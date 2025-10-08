import 'dart:async';
import 'dart:convert';

import 'package:auto_tm/screens/search_screen/model/search_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

// class SearchScreenController extends GetxController {

// final TextEditingController searchController = TextEditingController();
//   final FocusNode searchFocus = FocusNode();
//   final box = GetStorage();
//   void unFocus() {
//     searchFocus.unfocus();
//   }

//   final isSearchLoading = false.obs;
//   final searchResults = <Post>[].obs;

//   // Replace with your API endpoint
//   final String searchApiUrl = ApiKey.searchPostsKey;

//   void searchProducts(String query) async {
//     if (query.isEmpty) {
//       searchResults.clear();
//       return;
//     }

//     isSearchLoading.value = true;

//     try {
//       final response = await http.get(Uri.parse('$searchApiUrl?brand=true&model=true&photo=true&subscription=true&search=$query'),headers: {
//           "Content-Type": "application/json",
//           // 'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
//         },);

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         // final products = (data['products'] as List)
//         //     .map((item) => Product.fromJson(item))
//         //     .toList();
//         searchResults.value = data.map((item) => Post.fromJson(item)).toList();
//       } else {
//         searchResults.clear();
//       }
//     } catch (e) {
//       searchResults.clear();
//     } finally {
//       isSearchLoading.value = false;
//     }
//   }

//   Future<bool> refreshAccessToken() async {
//     try {
//       final refreshToken = box.read('REFRESH_TOKEN');

//       final response = await http.get(
//         Uri.parse(ApiKey.refreshTokenKey),
//         headers: {
//           "Content-Type": "application/json",
//           'Authorization': 'Bearer $refreshToken'
//         },
//       );

//       if (response.statusCode == 200 && response.body.isNotEmpty) {
//         final data = jsonDecode(response.body);
//         final newAccessToken = data['accessToken'];
//         if (newAccessToken != null) {
//           box.remove('ACCESS_TOKEN');
//           box.write('ACCESS_TOKEN', newAccessToken);
//           return true; // Indicate successful refresh
//         } else {
//           return false; // Indicate failed refresh
//         }
//       } if (response.statusCode == 406) {
//         Get.offAllNamed('/login');
//         return false; // Indicate failed refresh
//       } else {
//         return false; // Indicate failed refresh
//       }
//     } catch (e) {
//       return false; // Indicate failed refresh
//     }
//   }

//   void clearSearch() {
//     searchResults.clear();
//     searchController.clear();
//     searchFocus.unfocus();
//   }

//   @override
//   void onClose() {
//     searchController.dispose();
//     searchFocus.dispose();
//     super.onClose();
//   } 
// }


class SearchScreenController extends GetxController {
  final searchTextController = TextEditingController();
  final searchTextFocus = FocusNode();
  final box = GetStorage();
  final RxList<SearchModel> hints = <SearchModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int offset = 0;
  final int limit = 20;
  Timer? _debounce;

  void debouncedSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchHints(reset: true);
    });
  }

  Future<void> searchHints({bool reset = false}) async {
    final query = searchTextController.text.trim();
    if (query.isEmpty) {
      hints.clear();
      hasMore.value = false;
      return;
    }

    if (isLoading.value) return;

    isLoading.value = true;

    if (reset) {
      offset = 0;
      hints.clear();
      hasMore.value = true;
    }

    try {
      final response = await http.get(
        Uri.parse('http://216.250.13.51:3080/api/v1/brands/search?search=$query&limit=$limit&offset=$offset'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<SearchModel> fetched = (data['results'] as List)
            .map((item) => SearchModel.fromJson(item))
            .toList();

        hints.addAll(fetched);
        if (fetched.length < limit) {
          hasMore.value = false;
        } else {
          offset += limit;
        }
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }

    isLoading.value = false;
  }
}
