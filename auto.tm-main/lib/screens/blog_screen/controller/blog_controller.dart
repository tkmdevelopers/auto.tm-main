import 'dart:convert';

import 'package:auto_tm/screens/blog_screen/model/blog_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BlogController extends GetxController {
  final box = GetStorage();
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
      final response = await http.get(
        Uri.parse(ApiKey.getBlogsKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
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
      if (response.statusCode == 406) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return fetchBlogs(); // Call fetchBlogs again only if refresh was successful
        } else {
          // Handle the case where token refresh failed (e.g., show an error)
          (
            'Error',
            'Failed to refresh access token. Please log in again.'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          // Optionally navigate to the login screen if refresh consistently fails
          // Get.offAllNamed('/login');
        }
      } else {
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

  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = box.read('REFRESH_TOKEN');

      final response = await http.get(
        Uri.parse(ApiKey.refreshTokenKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        if (newAccessToken != null) {
          box.remove('ACCESS_TOKEN');
          box.write('ACCESS_TOKEN', newAccessToken);
          return true; // Indicate successful refresh
        } else {
          return false; // Indicate failed refresh
        }
      }
      if (response.statusCode == 406) {
        Get.offAllNamed('/register'); // Fixed: /login doesn't exist
        return false; // Indicate failed refresh
      } else {
        return false; // Indicate failed refresh
      }
    } catch (e) {
      return false; // Indicate failed refresh
    }
  }

  Future<String> fetchBlogDetails(String blogId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiKey.getOneBlogKey}$blogId"),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
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
