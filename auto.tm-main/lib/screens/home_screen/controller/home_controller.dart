import 'dart:isolate';

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

/// Page size for home feed; used for limit and offset increment.
const int kHomePageSize = 20;

class HomeController extends GetxController {
  final ScrollController scrollController = ScrollController();

  /// Threshold in pixels before maxScrollExtent to trigger pagination (load earlier).
  static const double _paginationThreshold = 200;

  var posts = <Post>[].obs;
  var isLoading = false.obs;
  var initialLoad = true.obs;
  var hasMore = true.obs;
  var offset = 0;

  /// Error state: when true, show error UI with retry.
  var isError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    fetchInitialData();
    scrollController.addListener(_onScroll);
    super.onInit();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _paginationThreshold) {
      fetchPosts();
    }
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
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
      isError.value = true;
      errorMessage.value = e.toString();
    } finally {
      FlutterNativeSplash.remove();
      initialLoad.value = false;
      if (isError.value) {
        _showErrorSnackbar();
      }
    }
  }

  void _showErrorSnackbar() {
    Get.snackbar(
      'home_error_title'.tr,
      'home_error_tap_retry'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
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
          'limit': kHomePageSize,
          'brand': true,
          'model': true,
          'photo': true,
          'subscription': true,
          'status': true,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is! List) {
          isError.value = true;
          errorMessage.value = 'Invalid response format';
          return;
        }
        final newPosts = await Isolate.run(() {
          return (data as List)
              .map((e) => Post.fromJson(e as Map<String, dynamic>))
              .toList();
        });

        if (newPosts.isNotEmpty) {
          posts.addAll(newPosts);
          offset += kHomePageSize;
        } else {
          hasMore.value = false;
        }
      } else {
        isError.value = true;
        final body = response.data;
        if (body is Map && body['message'] != null) {
          errorMessage.value = body['message'].toString();
        } else {
          final code = response.statusCode;
          errorMessage.value =
              code != null ? 'Request failed ($code)' : 'Request failed';
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
