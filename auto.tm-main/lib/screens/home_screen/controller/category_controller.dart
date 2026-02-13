import 'package:auto_tm/domain/models/category.dart';
import 'package:auto_tm/domain/repositories/common_repository.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController {
  final CommonRepository _repository;

  CategoryController() : _repository = Get.find<CommonRepository>();

  var isLoading = true.obs;
  var isLoading1 = true.obs;
  var categories = <Category>[].obs;
  var category = <Category>[].obs;
  var posts = <Post>[].obs;

  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final results = await _repository.fetchCategories();
      categories.assignAll(results);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategoryPosts(String uuid) async {
    isLoading1.value = true;
    try {
      final results = await _repository.fetchCategories();
      category.assignAll(results.where((item) => item.uuid == uuid).toList());
    } catch (e) {
      return;
    } finally {
      isLoading1.value = false;
    }
  }
}
