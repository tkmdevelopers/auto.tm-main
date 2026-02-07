import 'package:auto_tm/screens/blog_screen/model/blog_model.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BlogController extends GetxController {
  var blogs = <Blog>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBlogs();
  }

  Future<void> fetchBlogs() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = await ApiClient.to.dio.get('vlog');
      final jsonResponse = response.data;

      if (response.statusCode == 200 && jsonResponse != null) {
        final data = jsonResponse is Map && jsonResponse['data'] != null
            ? jsonResponse['data'] as List
            : (jsonResponse is List ? jsonResponse : <dynamic>[]);
        final map = <String, Blog>{};
        for (final item in data) {
          try {
            final blog = Blog.fromJson(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map));
            map[blog.uuid] = blog;
          } catch (_) {}
        }
        blogs.value = map.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      } else {
        Get.snackbar(
          'Error',
          'Failed to load blogs. Please try again later.'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
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
      final response = await ApiClient.to.dio.get('vlog/$blogId');
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        return (data['description'] as String?) ?? '';
      }
      return '';
    } catch (e) {
      return '';
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
