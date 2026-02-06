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
    // This function is only for the very first load to show the main shimmer
    initialLoad.value = true;
    try {
      await fetchPosts();
    } catch (e) {
      // Log error or show a message if needed
      debugPrint('Error fetching initial data: $e');
    } finally {
      FlutterNativeSplash.remove();
      initialLoad.value = false;
    }
  }

  Future<void> fetchPosts() async {
    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;

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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    try {
      // Reset all state for a pull-to-refresh
      isLoading.value = false;
      hasMore.value = true;
      offset = 0;
      posts.clear();
      await fetchInitialData();
    } catch (e) {
      // Ensure the refresh completes even on error
      debugPrint('Error refreshing data: $e');
    }
  }

}
