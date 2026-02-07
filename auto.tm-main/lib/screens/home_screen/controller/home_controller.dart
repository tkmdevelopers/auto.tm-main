import 'dart:convert';
import 'dart:isolate';

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final ScrollController scrollController = ScrollController();

  var posts = <Post>[].obs;
  var isLoading = false.obs; // Tracks pagination loading
  var initialLoad = true.obs; // Tracks the very first page load
  var hasMore = true.obs;
  var offset = 0;

  /// Error state: when true, show error UI with retry.
  var isError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    fetchInitialData();
    // Add the listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.offset) {
        fetchPosts();
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // --- FIX: Added this method back ---
  /// Scrolls the home screen list back to the top.
  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> fetchInitialData() async {
    initialLoad.value = true;
    isError.value = false;
    errorMessage.value = '';
    try {
      await fetchPosts();
      if (isError.value) {
        Get.snackbar(
          'home_error_title'.tr,
          'home_error_tap_retry'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
      isError.value = true;
      errorMessage.value = e.toString();
      Get.snackbar(
        'home_error_title'.tr,
        'home_error_tap_retry'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      FlutterNativeSplash.remove();
      initialLoad.value = false;
    }
  }

  Future<void> fetchPosts() async {
    isLoading.value = true;
    if (!hasMore.value) {
      isLoading.value = false;
      return;
    }

    try {
      final response = await ApiClient.to.dio.get(
        'posts',
        queryParameters: {
          'offset': offset,
          'limit': 20,
          'brand': true,
          'model': true,
          'photo': true,
          'subscription': true,
          'status': true,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final newPosts = await Isolate.run(() {
          final data = response.data;
          return data is List
              ? (data as List)
                  .map((e) => Post.fromJson(e as Map<String, dynamic>))
                  .toList()
              : <Post>[];
        });

        if (newPosts.isNotEmpty) {
          posts.addAll(newPosts);
          offset += 20;
        } else {
          hasMore.value = false;
        }
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      isError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Retry after error: clear error state and fetch from start.
  Future<void> retry() async {
    isError.value = false;
    errorMessage.value = '';
    hasMore.value = true;
    offset = 0;
    posts.clear();
    await fetchInitialData();
  }

  /// Pull-to-refresh: reset and reload. Future always completes so RefreshIndicator stops.
  Future<void> refreshData() async {
    isLoading.value = false;
    hasMore.value = true;
    offset = 0;
    isError.value = false;
    errorMessage.value = '';
    posts.clear();
    try {
      await fetchInitialData();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      // Future still completes; error state already set in fetchInitialData
    }
  }

}
