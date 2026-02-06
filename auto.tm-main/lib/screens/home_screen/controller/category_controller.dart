import 'dart:convert';

import 'package:auto_tm/screens/home_screen/model/category_model.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController {
  var isLoading = true.obs;
  var isLoading1 = true.obs;
  var categories = <Category>[].obs;
  var category = <Category>[].obs;
  var posts = <Post>[].obs;

  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.to.dio.get(
        'categories',
        queryParameters: {'photo': true, 'post': true},
      );
      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> jsonResponse = response.data is List
            ? response.data as List
            : json.decode(response.data is String ? response.data as String : '[]');
        categories.assignAll(
          jsonResponse
              .map((j) => Category.fromJson(j as Map<String, dynamic>))
              .toList(),
        );
      } else {
        throw Exception('Failed to load subcategories');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategoryPosts(String uuid) async {
    isLoading1.value = true;
    try {
      final response = await ApiClient.to.dio
          .get(
            'categories',
            queryParameters: {'photo': true, 'post': true},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> jsonResponse = response.data is List
            ? response.data as List
            : json.decode(response.data is String ? response.data as String : '[]');
        category.assignAll(
          jsonResponse
              .map((j) => Category.fromJson(j as Map<String, dynamic>))
              .where((item) => item.uuid == uuid)
              .toList(),
        );
      }
    } catch (e) {
      return;
    } finally {
      isLoading1.value = false;
    }
  }
}
