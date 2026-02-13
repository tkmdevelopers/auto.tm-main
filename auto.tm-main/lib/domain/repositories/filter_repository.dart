import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/post_filter.dart';

class PostSearchResult {
  final List<Post> posts;
  final int totalCount;

  PostSearchResult({required this.posts, required this.totalCount});
}

abstract class FilterRepository {
  Future<PostSearchResult> searchPosts({
    required int offset,
    required int limit,
    required PostFilter filters,
  });

  Future<int> getMatchCount(PostFilter filters);
}