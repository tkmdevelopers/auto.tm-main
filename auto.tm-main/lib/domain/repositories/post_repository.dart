import 'package:auto_tm/domain/models/post.dart';

abstract class PostRepository {
  Future<List<Post>> getFeedPosts({
    required int offset,
    required int limit,
    Map<String, dynamic>? filters,
  });

  Future<List<Post>> getMyPosts();

  Future<String?> createPost(Map<String, dynamic> postData);

  Future<void> deletePost(String uuid);
}
