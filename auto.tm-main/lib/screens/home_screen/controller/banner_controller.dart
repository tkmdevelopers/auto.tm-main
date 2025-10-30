import 'dart:convert';
import 'dart:isolate';

import 'package:auto_tm/screens/home_screen/model/banner_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class BannerController extends GetxController {
  var banners = <BannerModel>[].obs; // Observable list of BannerModel
  final box = GetStorage();
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
      final response = await http
          .get(
            Uri.parse(ApiKey.getBannersKey),
            headers: {
              "Content-Type": "application/json",
              'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
            },
          )
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        banners.value = await Isolate.run(() {
          List<dynamic> data = json.decode(response.body);
          return data
              .map((item) => BannerModel.fromJson(item))
              .toList(); // Parse JSON into BannerModel
        });
      }
      if (response.statusCode == 406) {
        // await refreshAccessToken();
        return fetchBanners(); // Retry after refreshing token
      }
    } catch (e) {
      return;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAccessToken() async {
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
          box.write('ACCESS_TOKEN', newAccessToken);
        } else {}
      }
      if (response.statusCode == 406) {
        Get.offAllNamed('/register'); // Fixed: /login doesn't exist
      } else {}
    } catch (e) {
      return;
    }
  }
}
