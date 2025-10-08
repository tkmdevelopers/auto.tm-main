import 'dart:convert';
import 'dart:isolate';

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  final box = GetStorage();
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
    await fetchPosts();
    FlutterNativeSplash.remove();
    initialLoad.value = false;
  }

  Future<void> fetchPosts() async {
    // Guard against multiple simultaneous fetches
    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;

    try {
      final response = await _makeGetRequest(
        "${ApiKey.getPostsKey}?offset=$offset&limit=20&brand=true&model=true&photo=true&subscription=true&status=true",
      );

      if (response != null) {
        final newPosts = await Isolate.run(() {
          final data = jsonDecode(response.body);
          return data is List
              ? data.map((e) => Post.fromJson(e)).toList()
              : <Post>[];
        });

        if (newPosts.isNotEmpty) {
          posts.addAll(newPosts);
          offset += 20;
        } else {
          hasMore.value = false;
        }
      }
    } finally {
      // This is crucial: always set isLoading to false after the attempt.
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    // Reset all state for a pull-to-refresh
    isLoading.value = false;
    hasMore.value = true;
    offset = 0;
    posts.clear();
    await fetchInitialData();
  }

  Future<http.Response?> _makeGetRequest(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return response;
    } catch (_) {}
    return null;
  }
}
