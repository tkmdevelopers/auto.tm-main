import 'package:auto_tm/domain/models/banner.dart';
import 'package:auto_tm/domain/repositories/common_repository.dart';
import 'package:get/get.dart';

class BannerController extends GetxController {
  final CommonRepository _repository;

  BannerController() : _repository = Get.find<CommonRepository>();

  var banners = <Banner>[].obs; // Observable list of Banner
  var isLoading = true.obs; // Loading indicator
  var currentPage = 0.obs; // Current page of the slider

  void setCurrentPage(int index) {
    currentPage.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      final results = await _repository.fetchBanners();
      banners.value = results;
    } catch (e) {
      return;
    } finally {
      isLoading.value = false;
    }
  }
}
