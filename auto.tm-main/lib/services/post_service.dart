import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:auto_tm/data/repositories/post_repository_impl.dart';
import 'package:auto_tm/domain/models/post.dart' as domain;
import 'package:auto_tm/domain/repositories/post_repository.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';

import 'package:auto_tm/data/repositories/post_repository_impl.dart';
import 'package:auto_tm/domain/repositories/post_repository.dart';
import 'package:auto_tm/domain/models/post.dart' as domain;

class PostService extends GetxService {
  static PostService get to => Get.find();

  final ApiClient _apiClient;
  late final PostRepository _repository;

  PostService(this._apiClient) : _repository = PostRepositoryImpl(_apiClient);

  // --- Post creation/management ---

  Future<String?> createPostDetails(Map<String, dynamic> postData) async {
    return _repository.createPost(postData);
  }

  Future<List<domain.Post>> fetchMyPosts() async {
    return _repository.getMyPosts();
  }

  Future<void> deleteMyPost(String uuid) async {
    return _repository.deletePost(uuid);
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

  /// Fetch feed posts starting from [offset].
  Future<List<domain.Post>> fetchFeedPosts({
    required int offset,
    required int limit,
    bool brand = true,
    bool model = true,
    bool photo = true,
    bool subscription = true,
    bool status = true,
  }) async {
    return _repository.getFeedPosts(
      offset: offset,
      limit: limit,
      filters: {
        'brand': brand,
        'model': model,
        'photo': photo,
        'subscription': subscription,
        'status': status,
      },
    );
  }

  // Brand & model fetching/caching is now handled by BrandModelService.
}
