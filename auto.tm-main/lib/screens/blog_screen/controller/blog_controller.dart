import 'package:auto_tm/domain/models/blog.dart';
import 'package:auto_tm/domain/repositories/common_repository.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BlogController extends GetxController {
  final CommonRepository _repository;

  BlogController() : _repository = Get.find<CommonRepository>();

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
      final results = await _repository.fetchBlogs();
      blogs.value = results..sort((a, b) => b.date.compareTo(a.date));
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

  Future<String> fetchBlogDetails(String blogId) async {
    try {
      final blog = await _repository.fetchBlogDetails(blogId);
      return blog?.description ?? '';
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
