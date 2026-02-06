import 'dart:convert';
import 'dart:isolate';

import 'package:auto_tm/screens/home_screen/model/banner_model.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';

class BannerController extends GetxController {
  var banners = <BannerModel>[].obs; // Observable list of BannerModel
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
      final response = await ApiClient.to.dio
          .get('banners')
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.data != null) {
        banners.value = await Isolate.run(() {
          final data = response.data is List
              ? response.data as List
              : (response.data is String
                  ? json.decode(response.data as String) as List
                  : <dynamic>[]);
          return data
              .map((item) => BannerModel.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      return;
    } finally {
      isLoading.value = false;
    }
  }
}
