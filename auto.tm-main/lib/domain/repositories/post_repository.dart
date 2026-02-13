import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/post_filter.dart';
import 'package:auto_tm/domain/models/comment.dart';

abstract class PostRepository {
  Future<List<Post>> getFeedPosts({
    required int offset,
    required int limit,
    PostFilter? filters,
  });

  Future<int> getPostsCount();

  Future<List<Post>> getMyPosts();

  Future<String?> createPost(Map<String, dynamic> postData);

  Future<void> deletePost(String uuid);

  Future<bool> uploadVideo(
    String postUuid,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });

  Future<bool> uploadPhoto(
    String postUuid,
    Uint8List bytes,
    int index, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });

  Future<Post?> getPost(String uuid);

  Future<List<Comment>> getComments(String postUuid);

  Future<Comment?> addComment({
    required String postUuid,
    required String message,
    String? replyToUuid,
  });

  Future<void> deletePostCascade(String postUuid);
}
