import 'dart:convert';

import 'package:auto_tm/screens/home_screen/model/category_model.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CategoryController extends GetxController {
  var isLoading = true.obs;
  var isLoading1 = true.obs;
  var categories = <Category>[].obs;
  var category = <Category>[].obs;
  final box = GetStorage();
  var posts = <Post>[].obs;

  // @override
  // void onInit() {
  //   fetchCategories();
  //   super.onInit();
  // }

  // Fetch subcategories with products and photos
  Future<void> fetchCategories() async {
    isLoading.value = true;
    final String baseUrl = ApiKey.getCategoriesKey;

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl?photo=true&post=true',
        ),
        headers: {
          // "Accept": "application/json",
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}'
        },
      );

      if (response.statusCode == 200) {
        // print('Response: ${response.body}');
        List<dynamic> jsonResponse = json.decode(response.body);
        categories.assignAll(
            jsonResponse.map((json) => Category.fromJson(json)).toList());
      } else {
        throw Exception('Failed to load subcategories');
      }
    // ignore: empty_catches
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAccesToken() async {
  try {
    final refreshToken = box.read('REFRESH_TOKEN');

    final response = await http.get(
      Uri.parse(ApiKey.refreshTokenKey),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $refreshToken'
      },
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['accessToken'];
      if (newAccessToken != null) {
        box.write('ACCESS_TOKEN', newAccessToken);
        await fetchCategories();
      } else {
      }
    } else {
    }
  } catch (e) {
    return;
  }
}

  void fetchCategoryPosts(String uuid) async {
    final String baseUrl = ApiKey.getCategoriesKey;
    isLoading1.value = true;

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?photo=true&post=true'),
        headers: {
          // "Accept": "application/json",
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}'
        },
      ).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        category.assignAll(
            jsonResponse.map((json) => Category.fromJson(json)).where((item) => item.uuid == uuid).toList());
      }
    } catch (e) {
      return;
    } finally {
      isLoading1.value = false;
    }
  }
}