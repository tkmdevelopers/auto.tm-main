import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/repositories/post_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

/// Page size for home feed; used for limit and offset increment.
const int kHomePageSize = 20;

enum HomeStatus { initial, loading, success, error, empty }

class HomeController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final PostRepository _postRepository;

  HomeController() : _postRepository = Get.find<PostRepository>();

  /// Threshold in pixels before maxScrollExtent to trigger pagination (load earlier).
  static const double _paginationThreshold = 200;

  final posts = <Post>[].obs;
  final totalPostsCount = 0.obs;
  final status = HomeStatus.initial.obs;
  final isPaginating = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;
  int offset = 0;

  @override
  void onInit() {
    fetchInitialData();
    scrollController.addListener(_onScroll);
    super.onInit();
  }

  void _onScroll() {
    if (!scrollController.hasClients || isPaginating.value || !hasMore.value) {
      return;
    }
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _paginationThreshold) {
      fetchPosts(isPagination: true);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

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
    status.value = HomeStatus.loading;
    errorMessage.value = '';
    try {
      // Parallel fetch for posts and count
      await Future.wait([
        fetchPosts(),
        _fetchCount(),
      ]);
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
      status.value = HomeStatus.error;
      errorMessage.value = e.toString();
      _showErrorSnackbar();
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _fetchCount() async {
    try {
      final count = await _postRepository.getPostsCount();
      totalPostsCount.value = count;
    } catch (_) {}
  }

  void _showErrorSnackbar() {
    Get.snackbar(
      'home_error_title'.tr,
      'home_error_tap_retry'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> fetchPosts({bool isPagination = false}) async {
    if (isPagination) {
      isPaginating.value = true;
    }

    try {
      final newPosts = await _postRepository.getFeedPosts(
        offset: offset,
        limit: kHomePageSize,
      );

      if (newPosts.isNotEmpty) {
        posts.addAll(newPosts);
        offset += kHomePageSize;
        if (!isPagination) {
          status.value = HomeStatus.success;
        }
      } else {
        if (!isPagination && posts.isEmpty) {
          status.value = HomeStatus.empty;
        }
        hasMore.value = false;
      }
    } catch (e) {
      if (isPagination) {
        Get.snackbar('Error', 'Failed to load more posts');
      } else {
        status.value = HomeStatus.error;
        errorMessage.value = e.toString();
      }
    } finally {
      isPaginating.value = false;
      // If we were loading the first page and didn't fail, ensure we are in a final state
      if (status.value == HomeStatus.loading) {
        status.value = posts.isEmpty ? HomeStatus.empty : HomeStatus.success;
      }
    }
  }

  /// Retry after error: clear error state and fetch from start.
  Future<void> retry() async {
    hasMore.value = true;
    offset = 0;
    posts.clear();
    await fetchInitialData();
  }

  /// Pull-to-refresh: reset and reload.
  Future<void> refreshData() async {
    hasMore.value = true;
    offset = 0;
    errorMessage.value = '';
    posts.clear();
    await fetchInitialData();
  }
}
