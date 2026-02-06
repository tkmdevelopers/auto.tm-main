import 'dart:convert';

import 'package:auto_tm/screens/blog_screen/model/blog_model.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BlogController extends GetxController {
  var blogs = <Blog>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBlogs();
  }

  void fetchBlogs() async {
    if (isLoading.value) return; // prevent concurrent fetches
    isLoading.value = true;
    try {
      final accessToken = await TokenStore.to.accessToken;
      final response = await http.get(
        Uri.parse(ApiKey.getBlogsKey),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        final List data = jsonResponse['data'];
        // Dedupe by uuid in case backend returns duplicates (e.g., join or pagination overlap)
        final map = <String, Blog>{};
        for (final item in data) {
          try {
            final blog = Blog.fromJson(item);
            map[blog.uuid] = blog; // last wins (or only) ensures uniqueness
          } catch (_) {
            // skip malformed item silently
          }
        }
        blogs.value = map.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // keep newest first
      }
      // Auth errors (401) are now handled by ApiClient interceptor for Dio calls.
      else {
        (
          'Error',
          'Failed to load blogs. Please try again later.'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      (
        'Error',
        'Error fetching blogs. Please check your internet connection.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Token refresh is now handled by the Dio ApiClient interceptor.
  // The duplicated refreshAccessToken() method has been removed.

  Future<String> fetchBlogDetails(String blogId) async {
    try {
      final accessToken = await TokenStore.to.accessToken;
      final response = await http.get(
        Uri.parse("${ApiKey.getOneBlogKey}$blogId"),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['description']; // The content contains text + image links
      } else {
        return "";
      }
    } catch (e) {
      return ""; // could localize but empty indicates failure
    }
  }

  String formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate); // Convert string to DateTime
    String formattedDate = DateFormat(
      'dd.MM.yyyy',
    ).format(dateTime); // Format to dd.MM.yyyy
    return formattedDate;
  }
}
