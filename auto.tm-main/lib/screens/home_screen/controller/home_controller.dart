import 'dart:async';
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

  // Memory management: limit posts in memory to prevent excessive memory usage
  static const int maxPostsInMemory = 200;
  static const int postsToRemoveWhenLimitReached = 20;

  // Scroll position preservation for better UX
  double? savedScrollPosition;

  // Debounce timer to prevent rapid scroll-triggered fetches
  Timer? _scrollDebounceTimer;

  @override
  void onInit() {
    fetchInitialData();
    // Add the listener for pagination with debouncing
    scrollController.addListener(() {
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        // ✅ FIX: Guard against disposed/unattached scrollController
        if (scrollController.hasClients &&
            scrollController.position.maxScrollExtent ==
                scrollController.offset) {
          fetchPosts();
        }
      });
    });
    super.onInit();
  }

  @override
  void onClose() {
    _scrollDebounceTimer?.cancel();
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

  /// Save current scroll position for restoration after navigation
  void saveScrollPosition() {
    if (scrollController.hasClients) {
      savedScrollPosition = scrollController.offset;
    }
  }

  /// Restore scroll position after returning to this screen
  void restoreScrollPosition() {
    if (savedScrollPosition != null && scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(savedScrollPosition!);
        }
      });
    }
  }

  /// Manage memory by limiting posts in memory
  void _manageMemory() {
    if (posts.length > maxPostsInMemory) {
      // Remove oldest posts to prevent excessive memory usage
      posts.removeRange(0, postsToRemoveWhenLimitReached);
      // Adjust offset to reflect removed posts
      offset = (offset - postsToRemoveWhenLimitReached).clamp(0, offset);
      debugPrint(
        'Memory management: Removed $postsToRemoveWhenLimitReached old posts. Current count: ${posts.length}',
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

          // Apply memory management after adding posts
          _manageMemory();
        } else {
          hasMore.value = false;
        }
      }
    } catch (e) {
      // Handle any errors during fetch
      debugPrint('Error fetching posts: $e');
    } finally {
      // This is crucial: always set isLoading to false after the attempt.
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
