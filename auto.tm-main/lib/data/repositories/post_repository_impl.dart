import 'dart:convert';
import 'package:auto_tm/data/dtos/post_dto.dart';
import 'package:auto_tm/data/mappers/post_mapper.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/repositories/post_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/models/post_dtos.dart' as legacy; // for Failure

class PostRepositoryImpl implements PostRepository {
  final ApiClient _apiClient;

  PostRepositoryImpl(this._apiClient);

  @override
  Future<List<Post>> getFeedPosts({
    required int offset,
    required int limit,
    Map<String, dynamic>? filters,
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
        if (filters != null) ...filters,
      };

      final response = await _apiClient.dio.get('posts', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<dynamic> rawList = (data is List 
            ? data 
            : json.decode(data is String ? data : '[]')) as List;
        
        return rawList
            .map((json) => PostMapper.fromDto(PostDto.fromJson(json as Map<String, dynamic>)))
            .toList();
      }
      return [];
    } catch (e) {
      throw legacy.Failure('Error fetching feed: $e');
    }
  }

  @override
  Future<List<Post>> getMyPosts() async {
    try {
      final response = await _apiClient.dio.get('posts/me');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<dynamic> rawPosts = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);

        return rawPosts
            .map((json) => PostMapper.fromDto(PostDto.fromJson(json as Map<String, dynamic>)))
            .toList();
      }
      return [];
    } catch (e) {
      throw legacy.Failure('Failed to load my posts: $e');
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
      throw legacy.Failure('Post creation failed: $e');
    }
  }

  @override
  Future<void> deletePost(String uuid) async {
    try {
      final response = await _apiClient.dio.delete('posts/$uuid');
      if (response.statusCode != 200) {
        throw legacy.Failure('Failed to delete post');
      }
    } catch (e) {
      throw legacy.Failure('Delete failed: $e');
    }
  }
}
