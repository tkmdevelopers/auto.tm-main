import 'dart:io';
import 'package:dio/dio.dart';
import 'package:auto_tm/data/mappers/banner_mapper.dart';
import 'package:auto_tm/data/mappers/blog_mapper.dart';
import 'package:auto_tm/data/mappers/category_mapper.dart';
import 'package:auto_tm/domain/models/banner.dart';
import 'package:auto_tm/domain/models/blog.dart';
import 'package:auto_tm/domain/models/category.dart';
import 'package:auto_tm/domain/repositories/common_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';

class CommonRepositoryImpl implements CommonRepository {
  final ApiClient _apiClient;

  CommonRepositoryImpl(this._apiClient);

  @override
  Future<List<Category>> fetchCategories() async {
    final response = await _apiClient.dio.get(
      'categories',
      queryParameters: {'photo': true, 'post': true},
    );
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((j) => CategoryMapper.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Banner>> fetchBanners() async {
    final response = await _apiClient.dio.get('banners');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((item) => BannerMapper.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Blog>> fetchBlogs({int offset = 0, int limit = 10}) async {
    final response = await _apiClient.dio.get(
      'vlog',
      queryParameters: {'offset': offset, 'limit': limit},
    );
    if (response.statusCode == 200 && response.data != null) {
      final jsonResponse = response.data;
      final data = jsonResponse is Map && jsonResponse['data'] != null
          ? jsonResponse['data'] as List
          : (jsonResponse is List ? jsonResponse : <dynamic>[]);
      return data
          .map(
            (item) => BlogMapper.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<Blog?> fetchBlogDetails(String uuid) async {
    final response = await _apiClient.dio.get('vlog/$uuid');
    if (response.statusCode == 200 && response.data != null) {
      return BlogMapper.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<String?> uploadBlogImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(RegExp(r'[/\\]')).last,
        ),
      });
      final response = await _apiClient.dio.post('photo/vlog', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map;
        final uuid = data['uuid'];
        if (uuid is Map) {
          final path = uuid['path'];
          if (path is Map && path['medium'] != null) {
            return path['medium'] as String;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Future<void> postBlog(String content) async {
    await _apiClient.dio.post('vlog', data: {'description': content});
  }
}
