import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/utils/key.dart'; // For ApiKey
import 'package:auto_tm/models/post_dtos.dart';
export 'package:auto_tm/models/post_dtos.dart';

class PostService extends GetxService {
  final ApiClient _apiClient;
  final GetStorage _box; // For caching brands/models

  PostService(this._apiClient) : _box = GetStorage();
  
  /// Test constructor that allows injecting a mock GetStorage
  PostService.withStorage(this._apiClient, this._box);

  // Brand/model data
  final Map<String, String> _brandNameById = {};
  final Map<String, String> _modelNameById = {};
  final Set<String> _fetchedBrandModels = <String>{}; // Track which models have been fetched

  // Cache keys and TTL
  static const _brandCacheKey = 'BRAND_CACHE_V1';
  static const _modelCacheKey = 'MODEL_CACHE_V1';
  static const _cacheTtl = Duration(hours: 6);

  // --- Post creation/management ---

  Future<String?> createPostDetails(Map<String, dynamic> postData) async {
    try {
      final response = await _apiClient.dio.post(
        'posts',
        data: postData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) return data['uuid']?.toString();
        return null;
      } else {
        final errorData = response.data is Map ? response.data as Map : <String, dynamic>{};
        final errorMsg =
            (errorData['error'] ?? errorData['message'] ?? 'Unknown error').toString();
        Get.log('Post creation failed (${response.statusCode}): $errorMsg');
        throw Failure(errorMsg); // Propagate as Failure
      }
    } on DioException catch (e) {
      Get.log('Post creation error: ${e.message}');
      throw Failure(e.response?.data['message'] ?? e.message);
    } catch (e) {
      Get.log('Post creation exception: $e');
      throw Failure(e.toString());
    }
  }

  Future<List<PostDto>> fetchMyPosts() async {
    try {
      final response = await _apiClient.dio
          .get('posts/me')
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> rawPosts;
        if (data is List) {
          rawPosts = data;
        } else if (data is Map && data['data'] is List) {
          rawPosts = data['data'] as List;
        } else {
          rawPosts = [];
        }

        return rawPosts
            .map((json) => PostDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Failure('Session expired. Please login again.');
      } else {
        throw Failure('Failed to load posts (${response.statusCode})');
      }
    } on TimeoutException {
      Get.log('Fetch my posts timeout');
      throw Failure('Request timed out. Please try again.');
    } on DioException catch (e) {
      Get.log('Fetch my posts error: ${e.message}');
      throw Failure(e.response?.data['message'] ?? e.message);
    } catch (e) {
      Get.log('Fetch my posts exception: $e');
      throw Failure('Failed to load posts: ${e.toString()}');
    }
  }

  Future<void> deleteMyPost(String uuid) async {
    try {
      final response = await _apiClient.dio.delete('posts/$uuid');

      if (response.statusCode != 200) {
        throw Failure('Failed to delete post (${response.statusCode})');
      }
    } on DioException catch (e) {
      Get.log('Delete my post error: ${e.message}');
      throw Failure(e.response?.data['message'] ?? e.message);
    } catch (e) {
      Get.log('Delete my post exception: $e');
      throw Failure('Failed to delete post: $e');
    }
  }

  Future<bool> uploadVideo(
    String postUuid,
    File file,
    bool usedCompressed, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final form = FormData.fromMap({
        'postId': postUuid,
        'uuid': postUuid,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        ),
      });

      final resp = await _apiClient.dio.post(
        'video/upload',
        data: form,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: const Duration(seconds: 300),
          receiveTimeout: const Duration(minutes: 2),
        ),
        onSendProgress: onSendProgress,
      );

      if (resp.statusCode != null && resp.statusCode! >= 300) {
        Get.log('Video upload failed (${resp.statusCode}): ${resp.data}');
        throw Failure('Video upload failed: ${resp.data ?? resp.statusCode}');
      }
      return true;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Failure('User cancelled');
      } else {
        final status = e.response?.statusCode;
        final body = e.response?.data;
        throw Failure(
          'Video upload error${status != null ? ' ($status)' : ''}: ${body ?? e.message}',
        );
      }
    } catch (e) {
      Get.log('Video upload exception: $e');
      throw Failure('Video upload exception: $e');
    }
  }

  Future<bool> uploadPhoto(
    String postUuid,
    Uint8List bytes,
    int index, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _apiClient.dio.post(
        'photo/posts',
        data: FormData.fromMap({
          'uuid': postUuid,
          'file': MultipartFile.fromBytes(
            bytes,
            filename:
                'photo_${index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        }),
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        onSendProgress: onSendProgress,
      );
      return true;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Failure('User cancelled');
      } else {
        final status = e.response?.statusCode;
        final body = e.response?.data;
        throw Failure(
          'Photo upload error${status != null ? ' ($status)' : ''}: ${body ?? e.message}',
        );
      }
    } catch (e) {
      Get.log('Photo upload exception: $e');
      throw Failure('Photo upload exception: $e');
    }
  }

  Future<void> deleteCreatedPostCascade(String postUuid) async {
    try {
      await _apiClient.dio
          .delete('posts/$postUuid')
          .timeout(const Duration(seconds: 15));
    } on DioException catch (e) {
      Get.log('Cascade delete failed: ${e.message}');
      // Don't re-throw, this is a best-effort cleanup
    } catch (e) {
      Get.log('Cascade delete exception: $e');
    }
  }

  // --- Brand & Model Data Fetching & Caching ---

  Future<List<BrandDto>> fetchBrands({bool forceRefresh = false}) async {
    List<BrandDto> currentBrands = [];
    if (!forceRefresh) {
      currentBrands = _hydrateBrandCache();
      if (currentBrands.isNotEmpty && _isBrandCacheFresh()) {
        return currentBrands;
      }
    }

    try {
      final resp = await _apiClient.dio
          .get('brands')
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && resp.data != null) {
        final decoded = resp.data;
        final List<BrandDto> parsed = _parseBrandList(decoded);
        _saveBrandCache(parsed);
        return parsed;
      } else if (resp.statusCode == 401) {
        throw Failure('Session expired. Please login again.');
      } else {
        throw Failure('Failed to load brands (Status ${resp.statusCode})');
      }
    } on TimeoutException {
      throw Failure('Request timed out. Please try again.');
    } on DioException catch (e) {
      Get.log('Fetch brands error: ${e.message}');
      throw Failure(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    } catch (e) {
      Get.log('Fetch brands exception: $e');
      throw Failure(e.toString());
    } finally {
      // If refreshed from API and it failed, try to fallback to cache
      if (currentBrands.isEmpty) {
        final cached = _hydrateBrandCache();
        if (cached.isNotEmpty) currentBrands.assignAll(cached);
      }
    }
  }

  Future<List<ModelDto>> fetchModels(
    String brandUuid, {
    bool forceRefresh = false,
  }) async {
    if (brandUuid.isEmpty) return [];

    List<ModelDto> currentModels = [];
    if (!forceRefresh) {
      currentModels = _hydrateModelCache(brandUuid);
      if (currentModels.isNotEmpty && _isModelCacheFresh(brandUuid)) {
        return currentModels;
      }
    }

    try {
      final resp = await _apiClient.dio
          .get('models', queryParameters: {'filter': brandUuid})
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && resp.data != null) {
        final decoded = resp.data;
        final List<ModelDto> parsed = _parseModelList(decoded);
        _saveModelCache(brandUuid, parsed);
        return parsed;
      } else if (resp.statusCode == 401) {
        throw Failure('Session expired. Please login again.');
      } else {
        throw Failure('Failed to load models (Status ${resp.statusCode})');
      }
    } on TimeoutException {
      throw Failure('Request timed out. Please try again.');
    } on DioException catch (e) {
      Get.log('Fetch models error: ${e.message}');
      throw Failure(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    } catch (e) {
      Get.log('Fetch models exception: $e');
      throw Failure(e.toString());
    } finally {
      // If refreshed from API and it failed, try to fallback to cache
      if (currentModels.isEmpty) {
        final cached = _hydrateModelCache(brandUuid);
        if (cached.isNotEmpty) currentModels.assignAll(cached);
      }
    }
  }

  // --- Internal caching logic ---
  bool _isBrandCacheFresh() {
    try {
      final raw = _box.read(_brandCacheKey);
      if (raw is Map && raw['storedAt'] is String) {
        final ts = DateTime.tryParse(raw['storedAt']);
        if (ts == null) return false;
        return DateTime.now().difference(ts) < _cacheTtl;
      }
    } catch (_) {}
    return false;
  }

  bool _isModelCacheFresh(String brandUuid) {
    try {
      final raw = _box.read(_modelCacheKey);
      if (raw is Map && raw[brandUuid] is Map) {
        final entry = raw[brandUuid];
        final ts = DateTime.tryParse(entry['storedAt'] ?? '');
        if (ts == null) return false;
        return DateTime.now().difference(ts) < _cacheTtl;
      }
    } catch (_) {}
    return false;
  }

  void _saveBrandCache(List<BrandDto> list) {
    try {
      final map = {
        'storedAt': DateTime.now().toIso8601String(),
        'items': list.map((b) => {'uuid': b.uuid, 'name': b.name}).toList(),
      };
      _box.write(_brandCacheKey, map);
    } catch (_) {}
  }

  void _saveModelCache(String brandUuid, List<ModelDto> list) {
    try {
      final raw = _box.read(_modelCacheKey);
      Map<String, dynamic> cache = {};
      if (raw is Map) cache = Map<String, dynamic>.from(raw);
      cache[brandUuid] = {
        'storedAt': DateTime.now().toIso8601String(),
        'items': list.map((m) => {'uuid': m.uuid, 'name': m.name}).toList(),
      };
      _box.write(_modelCacheKey, cache);
    } catch (_) {}
  }

  List<BrandDto> _hydrateBrandCache() {
    try {
      final raw = _box.read(_brandCacheKey);
      if (raw is Map && raw['items'] is List) {
        return (raw['items'] as List)
            .whereType<Map>()
            .map((m) => BrandDto.fromJson(Map<String, dynamic>.from(m)))
            .where((b) => b.uuid.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  List<ModelDto> _hydrateModelCache(String brandUuid) {
    try {
      final raw = _box.read(_modelCacheKey);
      if (raw is Map && raw[brandUuid] is Map) {
        final entry = raw[brandUuid];
        return (entry['items'] as List?)
                ?.whereType<Map>()
                .map((m) => ModelDto.fromJson(Map<String, dynamic>.from(m)))
                .where((m) => m.uuid.isNotEmpty)
                .toList() ??
            [];
      }
    } catch (_) {}
    return [];
  }

  // --- DTO Parsing Helpers (moved from PostController) ---
  List<BrandDto> _parseBrandList(dynamic decoded) {
    try {
      final dynamic listCandidate = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] is List)
          ? decoded['data']
          : [];
      if (listCandidate is! List) return [];
      return listCandidate
          .whereType<Map>()
          .map((m) => BrandDto.fromJson(Map<String, dynamic>.from(m)))
          .where((b) => b.uuid.isNotEmpty && b.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<ModelDto> _parseModelList(dynamic decoded) {
    try {
      final dynamic listCandidate = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] is List)
          ? decoded['data']
          : [];
      if (listCandidate is! List) return [];
      return listCandidate
          .whereType<Map>()
          .map((m) => ModelDto.fromJson(Map<String, dynamic>.from(m)))
          .where((m) => m.uuid.isNotEmpty && m.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
