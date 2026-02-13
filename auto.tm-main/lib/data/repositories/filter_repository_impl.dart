import 'package:auto_tm/data/mappers/post_mapper.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/post_filter.dart';
import 'package:auto_tm/domain/repositories/filter_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';

class FilterRepositoryImpl implements FilterRepository {
  final ApiClient _apiClient;

  FilterRepositoryImpl(this._apiClient);

  @override
  Future<PostSearchResult> searchPosts({
    required int offset,
    required int limit,
    required PostFilter filters,
  }) async {
    final queryParams = {
      'offset': offset,
      'limit': limit,
      'brand': true,
      'model': true,
      'photo': true,
      'subscription': true,
      'status': true,
      ...filters.toQueryParams(),
    };
    final response = await _apiClient.dio.get(
      'posts',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      
      // The backend now returns { count, rows } for findAndCountAll
      if (data is Map<String, dynamic>) {
        final List rawList = data['rows'] ?? [];
        final int totalCount = data['count'] ?? 0;
        
        final posts = rawList
            .map((item) => PostMapper.fromJson(item as Map<String, dynamic>))
            .toList();
            
        return PostSearchResult(posts: posts, totalCount: totalCount);
      }
    }
    return PostSearchResult(posts: [], totalCount: 0);
  }

  @override
  Future<int> getMatchCount(PostFilter filters) async {
    final queryParams = {
      ...filters.toQueryParams(),
      'countOnly': true,
      'status': true,
    };
    
    final response = await _apiClient.dio.get(
      'posts',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['count'] ?? 0;
      }
    }
    return 0;
  }
}