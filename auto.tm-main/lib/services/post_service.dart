import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/utils/key.dart'; // For ApiKey

/// Simple failure wrapper for error handling
class Failure {
  final String? message;
  Failure(this.message);
  @override
  String toString() => message ?? 'Unknown error';
}

/// Brand data transfer object
class BrandDto {
  final String uuid;
  final String name;

  BrandDto({required this.uuid, required this.name});

  factory BrandDto.fromJson(Map<String, dynamic> json) => BrandDto(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
}

/// Model data transfer object
class ModelDto {
  final String uuid;
  final String name;

  ModelDto({required this.uuid, required this.name});

  factory ModelDto.fromJson(Map<String, dynamic> json) => ModelDto(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
}

/// Post data transfer object
class PostDto {
  final String uuid;
  final String brand;
  final String model;
  final String brandId; // raw brandsId from backend (may be empty)
  final String modelId; // raw modelsId from backend (may be empty)
  final double price;
  final String photoPath;
  final double year;
  final double milleage;
  final String currency;
  final String createdAt;
  final bool?
  status; // nullable: null -> pending moderation, true -> active, false -> declined/inactive

  PostDto({
    required this.uuid,
    required this.brand,
    required this.model,
    required this.brandId,
    required this.modelId,
    required this.price,
    required this.photoPath,
    required this.year,
    required this.milleage,
    required this.currency,
    required this.createdAt,
    required this.status,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) => PostDto(
    uuid: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
    brand: _extractBrand(json),
    model: _extractModel(json),
    brandId: json['brandsId']?.toString() ?? '',
    modelId: json['modelsId']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    photoPath: _extractPhotoPath(json),
    year: (json['year'] as num?)?.toDouble() ?? 0.0,
    milleage: (json['milleage'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency']?.toString() ?? '',
    createdAt: json['createdAt']?.toString() ?? '',
    status: json.containsKey('status') ? json['status'] as bool? : null,
  );

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'brand': brand,
    'model': model,
    'brandsId': brandId,
    'modelsId': modelId,
    'price': price,
    'photoPath': photoPath,
    'year': year,
    'milleage': milleage,
    'currency': currency,
    'createdAt': createdAt,
    'status': status,
  };
}

// --- PostDto parsing helpers ---
String _extractBrand(Map<String, dynamic> json) {
  // Prefer explicit name fields first
  final candidates = [json['brandName'], json['brand'], json['brandsName']];
  for (final c in candidates) {
    if (c is String && c.trim().isNotEmpty) return c.trim();
  }
  final brands = json['brands'];
  if (brands is Map) {
    final name = brands['name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    // Sometimes API might nest differently
    final b2 = brands['brand'];
    if (b2 is String && b2.trim().isNotEmpty) return b2.trim();
  } else if (brands is String && brands.trim().isNotEmpty) {
    // Avoid returning full map string representation like {uuid:..., name:...}
    if (brands.startsWith('{') && brands.contains('name:')) {
      // Try to extract name via regex
      final match = RegExp(r'name:([^,}]+)').firstMatch(brands);
      if (match != null) return match.group(1)!.trim();
    } else {
      return brands.trim();
    }
  }
  // Fallback to id (will later be resolved to name)
  final id = json['brandsId']?.toString();
  return id ?? '';
}

String _extractModel(Map<String, dynamic> json) {
  final candidates = [json['modelName'], json['model'], json['modelsName']];
  for (final c in candidates) {
    if (c is String && c.trim().isNotEmpty) return c.trim();
  }
  final models = json['models'];
  if (models is Map) {
    final name = models['name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    final m2 = models['model'];
    if (m2 is String && m2.trim().isNotEmpty) return m2.trim();
  } else if (models is String && models.trim().isNotEmpty) {
    if (models.startsWith('{') && models.contains('name:')) {
      final match = RegExp(r'name:([^,}]+)').firstMatch(models);
      if (match != null) return match.group(1)!.trim();
    } else {
      return models.trim();
    }
  }
  final id = json['modelsId']?.toString();
  return id ?? '';
}

String _extractPhotoPath(Map<String, dynamic> json) {
  final direct = json['photoPath'];
  if (direct is String && direct.trim().isNotEmpty) return direct.trim();

  final photo = json['photo'];
  // Case: photo is a List (home feed style)
  if (photo is List && photo.isNotEmpty) {
    for (final item in photo) {
      if (item is Map) {
        // Typical nested variant map under 'path'
        final p = item['path'];
        if (p is Map) {
          final variant = _pickImageVariant(p);
          if (variant != null) return variant;
        }
        for (final key in ['path', 'photoPath', 'originalPath', 'url']) {
          final v = item[key];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      } else if (item is String && item.trim().isNotEmpty) {
        return item.trim();
      }
    }
  }

  if (photo is Map) {
    for (final key in ['path', 'photoPath', 'originalPath', 'url']) {
      final v = photo[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final nested = photo['path'];
    if (nested is Map) {
      final variant = _pickImageVariant(nested);
      if (variant != null) return variant;
    }
  }

  final photos = json['photos'];
  if (photos is List && photos.isNotEmpty) {
    final first = photos.first;
    if (first is Map) {
      for (final key in ['path', 'photoPath', 'originalPath', 'url']) {
        final v = first[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      final nested = first['path'];
      if (nested is Map) {
        final variant = _pickImageVariant(nested);
        if (variant != null) return variant;
      }
    } else if (first is String && first.trim().isNotEmpty) {
      return first.trim();
    }
  }

  // Deep fallback scan
  final deep = _deepFindFirstImagePath(json);
  if (deep != null) return deep;

  if (Get.isLogEnable) {
    // ignore: avoid_print
    print(
      '[PostDto][photo] no photo path keys found (deep fallback also empty) keys=${json.keys}',
    );
  }
  return '';
}

String? _pickImageVariant(Map variantMap) {
  const order = ['medium', 'small', 'originalPath', 'original', 'large'];
  for (final k in order) {
    final v = variantMap[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  for (final value in variantMap.values) {
    if (value is Map) {
      final url = value['url'];
      if (url is String && url.trim().isNotEmpty) return url.trim();
    } else if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String? _deepFindFirstImagePath(dynamic node, {int depth = 0}) {
  if (depth > 5) return null;
  if (node is String) {
    final s = node.trim();
    if (s.isNotEmpty && _looksLikeImagePath(s)) return s;
  } else if (node is Map) {
    for (final entry in node.entries) {
      final found = _deepFindFirstImagePath(entry.value, depth: depth + 1);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final v in node) {
      final found = _deepFindFirstImagePath(v, depth: depth + 1);
      if (found != null) return found;
    }
  }
  return null;
}

bool _looksLikeImagePath(String s) {
  return RegExp(
    r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$',
    caseSensitive: false,
  ).hasMatch(s);
}

/// Tri-state status mapping for nullable boolean status.
enum PostStatusTri { pending, active, inactive }

extension PostDtoStatusExt on PostDto {
  PostStatusTri get triStatus {
    if (status == null) return PostStatusTri.pending;
    return status! ? PostStatusTri.active : PostStatusTri.inactive;
  }

  String statusLabel({String? pending, String? active, String? inactive}) {
    switch (triStatus) {
      case PostStatusTri.pending:
        return pending ?? 'post_status_pending'.tr;
      case PostStatusTri.active:
        return active ?? 'post_status_active'.tr;
      case PostStatusTri.inactive:
        return inactive ?? 'post_status_declined'.tr;
    }
  }
}

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
