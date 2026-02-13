import 'dart:io';
import 'package:auto_tm/domain/models/banner.dart';
import 'package:auto_tm/domain/models/blog.dart';
import 'package:auto_tm/domain/models/category.dart';

abstract class CommonRepository {
  Future<List<Category>> fetchCategories();
  Future<List<Banner>> fetchBanners();
  Future<List<Blog>> fetchBlogs({int offset = 0, int limit = 10});
  Future<Blog?> fetchBlogDetails(String uuid);
  Future<String?> uploadBlogImage(File file);
  Future<void> postBlog(String content);
}
