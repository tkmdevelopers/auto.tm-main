import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:auto_tm/data/dtos/post_dto.dart';
import 'package:auto_tm/data/mappers/post_mapper.dart';
import 'package:auto_tm/data/mappers/comment_mapper.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/post_filter.dart';
import 'package:auto_tm/domain/models/comment.dart';
import 'package:auto_tm/domain/repositories/post_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/utils/failure.dart';

class PostRepositoryImpl implements PostRepository {
  final ApiClient _apiClient;

  PostRepositoryImpl(this._apiClient);

  @override
  Future<List<Post>> getFeedPosts({
    required int offset,
    required int limit,
    PostFilter? filters,
  }) async {
    try {
      final queryParams = {
        'offset': offset,
        'limit': limit,
        'brand': true,
        'model': true,
        'photo': true,
        'subscription': true,
        'status': true,
        if (filters != null) ...filters.toQueryParams(),
      };

      final response = await _apiClient.dio.get(
        'posts',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        List<dynamic> rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          rawList = data['rows'] ?? data['data'] ?? [];
        } else if (data is String) {
          final decoded = json.decode(data);
          if (decoded is List) {
            rawList = decoded;
          } else if (decoded is Map<String, dynamic>) {
            rawList = decoded['rows'] ?? decoded['data'] ?? [];
          }
        }

        return rawList
            .map(
              (json) => PostMapper.fromDto(
                PostDto.fromJson(json as Map<String, dynamic>),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Failure('Error fetching feed: $e');
    }
  }

  @override
  Future<int> getPostsCount() async {
    try {
      final response = await _apiClient.dio.get('posts/count');
      debugPrint('[PostRepo] Count response: ${response.statusCode} ${response.data}');
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return (response.data['posts_count'] ?? 0) as int;
      }
      return 0;
    } catch (e) {
      debugPrint('[PostRepo] Count error: $e');
      // If endpoint requires auth and fails, return 0 (or handle silently)
      return 0;
    }
  }

  @override
  Future<List<Post>> getMyPosts() async {
    try {
      final response = await _apiClient.dio.get('posts/me');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> rawPosts = [];
        
        if (data is List) {
          rawPosts = data;
        } else if (data is Map<String, dynamic>) {
          rawPosts = data['rows'] ?? data['data'] ?? [];
        }

        return rawPosts
            .map(
              (json) => PostMapper.fromDto(
                PostDto.fromJson(json as Map<String, dynamic>),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Failure('Failed to load my posts: $e');
    }
  }

  @override
  Future<String?> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _apiClient.dio.post('posts', data: postData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['uuid']?.toString();
      }
      return null;
    } catch (e) {
      throw Failure('Post creation failed: $e');
    }
  }

  @override
  Future<void> deletePost(String uuid) async {
    try {
      final response = await _apiClient.dio.delete('posts/$uuid');
      if (response.statusCode != 200) {
        throw Failure('Failed to delete post');
      }
    } catch (e) {
      throw Failure('Delete failed: $e');
    }
  }

  @override
  Future<bool> uploadVideo(
    String postUuid,
    File file, {
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
      throw Failure('Video upload exception: $e');
    }
  }

  @override
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
      throw Failure('Photo upload exception: $e');
    }
  }

  @override
  Future<Post?> getPost(String uuid) async {
    final response = await _apiClient.dio.get(
      'posts/$uuid',
      queryParameters: {'model': true, 'brand': true, 'photo': true},
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : json.decode(
                  response.data is String ? response.data as String : '{}',
                )
                as Map<String, dynamic>;
      return PostMapper.fromJson(data);
    }
    return null;
  }

  @override
  Future<List<Comment>> getComments(String postUuid) async {
    final response = await _apiClient.dio.get(
      'comments',
      queryParameters: {'postId': postUuid},
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data is Map && data['data'] != null)
          ? (data['data'] as List)
          : (data is Map && data['results'] != null)
          ? (data['results'] as List)
          : [];
      return list
          .map(
            (e) => CommentMapper.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<Comment?> addComment({
    required String postUuid,
    required String message,
    String? replyToUuid,
  }) async {
    final commentData = {
      "postId": postUuid,
      "message": message,
      'replyTo': replyToUuid,
    };

    final response = await _apiClient.dio.post('comments', data: commentData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : jsonDecode(response.data is String ? response.data as String : '{}')
                as Map<String, dynamic>;
      return CommentMapper.fromJson(data);
    }
    return null;
  }

  @override
  Future<void> deletePostCascade(String postUuid) async {
    try {
      await _apiClient.dio
          .delete('posts/$postUuid')
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      // Best-effort cleanup
    }
  }
}
