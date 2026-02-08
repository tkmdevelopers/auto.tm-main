import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/models/post_dtos.dart';
export 'package:auto_tm/models/post_dtos.dart';

class PostService extends GetxService {
  static PostService get to => Get.find();

  final ApiClient _apiClient;
  final GetStorage _box; // For caching brands/models

  PostService(this._apiClient) : _box = GetStorage();

  /// Test constructor that allows injecting a mock GetStorage
  PostService.withStorage(this._apiClient, this._box);

  // --- Post creation/management ---

  Future<String?> createPostDetails(Map<String, dynamic> postData) async {
    try {
      final response = await _apiClient.dio.post('posts', data: postData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) return data['uuid']?.toString();
        return null;
      } else {
        final errorData = response.data is Map
            ? response.data as Map
            : <String, dynamic>{};
        final errorMsg =
            (errorData['error'] ?? errorData['message'] ?? 'Unknown error')
                .toString();
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

  // Brand & model fetching/caching is now handled by BrandModelService.
}
