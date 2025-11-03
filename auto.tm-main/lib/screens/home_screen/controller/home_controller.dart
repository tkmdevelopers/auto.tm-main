import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

enum FeedState { initialLoading, idle, paginating, refreshing, error }

class HomeController extends GetxController {
  final box = GetStorage();
  final ScrollController scrollController = ScrollController();

  var posts = <Post>[].obs;
  // Legacy observables retained temporarily for UI binding compatibility
  var isLoading =
      false.obs; // true while a network fetch (pagination or refresh) is active
  var initialLoad = true.obs; // true ONLY during very first load for shimmer
  var hasMore = true.obs;
  var _isRefreshing =
      false.obs; // Tracks active refresh to prevent concurrent operations
  final _feedState = FeedState.initialLoading.obs;
  // Monotonic offset (number of items already requested); never decremented.
  int offset = 0;
  // Track UUIDs to prevent duplicate posts injection when backend returns overlapping pages or refresh merges.
  final Set<String> _seenPostUuids = <String>{};

  // ✅ FIX 4: Store previous posts for error recovery
  List<Post> _previousPosts = [];
  int _previousOffset = 0;

  // Memory management: limit posts in memory to prevent excessive memory usage
  static const int maxPostsInMemory = 200;
  static const int postsToRemoveWhenLimitReached = 20;

  // Scroll position preservation for better UX
  double? savedScrollPosition;

  // Debounce timer to prevent rapid scroll-triggered fetches
  Timer? _scrollDebounceTimer;
  // Phase 3.3: Track which image URLs we've already prefetched to avoid duplicates
  final Set<String> _prefetchedFeedUrls = <String>{};

  // ✅ FIX 3: Cancellation token for in-flight requests
  bool _cancelPendingFetch = false;
  // Phase 3.2: Periodic telemetry log timer
  Timer? _telemetryTimer;
  // Dev toggle (could be sourced from remote config / settings later)
  static const bool _enableTelemetryPeriodicLog = true;

  // Base URL accessor (could be moved to config/service)
  // Base API root (ends with /) from .env via ApiKey.ip
  String get _baseUrl => ApiKey.ip.endsWith('/')
      ? ApiKey.ip.substring(0, ApiKey.ip.length - 1)
      : ApiKey.ip;

  // Estimate item extent for index calculation (feed card approximate height)
  static const double _estimatedItemExtent = 260; // includes padding/margins
  int _lastPrefetchAnchorIndex =
      -1; // last index we triggered adjacent prefetch for

  @override
  void onInit() {
    fetchInitialData();
    // Add the listener for pagination with debouncing
    scrollController.addListener(() {
      // ✅ FIX 1: Don't trigger pagination during refresh
      if (_isRefreshing.value) return;

      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        // ✅ FIX: Guard against disposed/unattached scrollController
        if (scrollController.hasClients &&
            scrollController.position.maxScrollExtent ==
                scrollController.offset &&
            !_isRefreshing.value) {
          // ✅ FIX 1: Double-check refresh state
          fetchPosts();
        }
        // Phase 3.3: Predictive adjacent feed image prefetch
        if (!_isRefreshing.value) {
          // ✅ FIX 1: Skip prefetch during refresh
          _maybePrefetchAdjacentFeedItems();
        }
      });
    });
    // Phase 3.2: Periodic telemetry logging every 60s (debug use only)
    if (_enableTelemetryPeriodicLog) {
      _telemetryTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        final telemetry = CachedImageHelper.getTelemetry();
        debugPrint('[HomeController][Telemetry] ${telemetry.toString()}');
      });
    }
    super.onInit();
  }

  @override
  void onClose() {
    _scrollDebounceTimer?.cancel();
    _telemetryTimer?.cancel();
    scrollController.dispose();
    _prefetchedFeedUrls.clear();
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
    // ✅ FIX 5: Guard against restoring during refresh or empty data state
    if (savedScrollPosition != null &&
        scrollController.hasClients &&
        !_isRefreshing.value &&
        posts.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (scrollController.hasClients &&
            !_isRefreshing.value &&
            posts.isNotEmpty) {
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
      // NOTE: We do NOT decrement offset; it is monotonic (represents total items fetched so far).
      debugPrint(
        'Memory management: Removed $postsToRemoveWhenLimitReached old posts. Current count: ${posts.length}',
      );
    }
  }

  void _setState(FeedState s) {
    if (_feedState.value == s) return;
    _feedState.value = s;
    switch (s) {
      case FeedState.initialLoading:
        initialLoad.value = true;
        isLoading.value = true;
        _isRefreshing.value = false;
        break;
      case FeedState.refreshing:
        _isRefreshing.value = true;
        isLoading.value = true;
        initialLoad.value = false;
        break;
      case FeedState.paginating:
        isLoading.value = true;
        initialLoad.value = false;
        break;
      case FeedState.idle:
        isLoading.value = false;
        _isRefreshing.value = false;
        initialLoad.value = false;
        break;
      case FeedState.error:
        isLoading.value = false;
        _isRefreshing.value = false;
        // initialLoad set false so UI can show empty/error view
        initialLoad.value = false;
        break;
    }
    debugPrint('[HomeController] State -> $s');
  }

  Future<void> fetchInitialData({bool isRefreshContext = false}) async {
    if (isRefreshContext) {
      _setState(FeedState.refreshing);
    } else {
      _setState(FeedState.initialLoading);
    }
    try {
      await fetchPosts();
      _setState(FeedState.idle);
    } catch (e) {
      _setState(FeedState.error);
      rethrow;
    } finally {
      if (_feedState.value == FeedState.initialLoading) {
        FlutterNativeSplash.remove();
      }
    }
  }

  Future<void> fetchPosts() async {
    // Decide state transitions: only set paginating if idle & not initial or refresh
    if (!hasMore.value) return;
    if (isLoading.value && !_isRefreshing.value) return; // already loading
    if (_feedState.value == FeedState.initialLoading ||
        _feedState.value == FeedState.refreshing) {
      // initial load / refresh already set loading flags
    } else {
      _setState(FeedState.paginating);
    }

    _cancelPendingFetch = false; // Reset cancellation flag
    const limit = 20;

    try {
      final response = await _makeGetRequest(
        "${ApiKey.getPostsKey}?offset=$offset&limit=$limit&brand=true&model=true&photo=true&subscription=true&status=true",
      );

      // ✅ FIX 3: Check if fetch was cancelled (e.g., by refresh)
      if (_cancelPendingFetch) {
        debugPrint('Fetch cancelled - refresh initiated');
        return;
      }

      if (response != null) {
        final newPosts = await Isolate.run(() {
          final data = jsonDecode(response.body);
          return data is List
              ? data.map((e) => Post.fromJson(e)).toList()
              : <Post>[];
        });

        // ✅ FIX 3: Check cancellation after async isolate work
        if (_cancelPendingFetch) {
          debugPrint('Fetch cancelled after JSON parse - refresh initiated');
          return;
        }

        if (newPosts.isNotEmpty) {
          // Deduplicate based on UUID presence
          final List<Post> unique = [];
          for (final p in newPosts) {
            if (_seenPostUuids.add(p.uuid)) {
              unique.add(p);
            }
          }
          if (unique.isNotEmpty) {
            posts.addAll(unique);
            offset += unique.length; // advance by actual unique items added
            // Apply memory management after adding posts
            _manageMemory();
            // Trigger initial batch pre-warm (Phase 3.3) when first page loads (after first non-empty unique batch)
            if (offset == unique.length) {
              _prewarmInitialFeedImages();
            }
          }
          // If returned batch size < requested limit OR zero unique items were added, mark hasMore false.
          if (newPosts.length < limit || unique.isEmpty) {
            hasMore.value = false;
          }
        } else {
          hasMore.value = false;
        }
      }
    } catch (e) {
      // Handle any errors during fetch
      debugPrint('Error fetching posts: $e');
    } finally {
      // This is crucial: always set isLoading to false after the attempt.
      // If we were paginating, go back idle (unless still refreshing)
      if (_feedState.value == FeedState.paginating) {
        _setState(FeedState.idle);
      } else if (_feedState.value == FeedState.refreshing) {
        // Keep refreshing flag; refreshData() will reset.
      } else if (_feedState.value == FeedState.initialLoading) {
        // initial load completion handled in fetchInitialData
      }
    }
  }

  // Phase 3.3: Prewarm first screen worth of images after initial load
  Future<void> _prewarmInitialFeedImages() async {
    try {
      if (posts.isEmpty) return;
      // Take first ~6 posts (roughly first couple rows)
      final initial = posts.take(6).where((p) => p.photos.isNotEmpty).toList();
      if (initial.isEmpty) return;
      final urls = initial
          .map((p) => p.photos.first.bestPath)
          .where((path) => path.isNotEmpty)
          .map((path) => CachedImageHelper.buildUrlForPrefetch(path, _baseUrl))
          .where((url) => !_prefetchedFeedUrls.contains(url))
          .toList();
      _prefetchedFeedUrls.addAll(urls);
      if (urls.isNotEmpty) {
        debugPrint(
          '[HomeController] 🔥 Pre-warming initial feed images (${urls.length})',
        );
        // Use longer timeout (12s) for initial feed prewarm to handle slow first loads
        await CachedImageHelper.prewarmCache(
          urls,
          maxConcurrent: 3,
          timeout: const Duration(seconds: 12),
        );
      }
    } catch (e) {
      debugPrint('[HomeController] ⚠️ Initial prewarm failed: $e');
    }
  }

  // Phase 3.3: Predictively prefetch images ahead of current scroll position
  void _maybePrefetchAdjacentFeedItems() {
    if (!scrollController.hasClients || posts.isEmpty) return;
    final offsetPx = scrollController.position.pixels;
    // Rough index estimate based on fixed extent assumption
    final currentIndex = (offsetPx / _estimatedItemExtent).floor();
    if (currentIndex < 0) return;
    // Only trigger when user advances at least 2 items beyond last anchor
    if (_lastPrefetchAnchorIndex != -1 &&
        currentIndex - _lastPrefetchAnchorIndex < 2) {
      return;
    }
    _lastPrefetchAnchorIndex = currentIndex;

    // Invoke utility to prefetch next 3 items' first images
    // Use 15s timeout for feed adjacent prefetch (same as post details for consistency)
    CachedImageHelper.prefetchAdjacentFeedItems(
      currentIndex: currentIndex,
      posts: posts,
      baseUrl: _baseUrl,
      adjacentCount: 3,
      prefetchedUrls: _prefetchedFeedUrls,
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> refreshData() async {
    if (_feedState.value == FeedState.refreshing) return; // already refreshing
    debugPrint('[HomeController] 🔄 Refresh initiated');
    _cancelPendingFetch = true; // cancel in-flight pagination
    _previousPosts = List.from(posts);
    _previousOffset = offset;
    hasMore.value = true;
    offset = 0;
    posts.clear();
    _seenPostUuids.clear();
    _prefetchedFeedUrls.clear();
    _lastPrefetchAnchorIndex = -1;
    _scrollDebounceTimer?.cancel();
    try {
      await fetchInitialData(isRefreshContext: true);
      _previousPosts.clear();
      _previousOffset = 0;
      debugPrint('[HomeController] ✅ Refresh success (${posts.length} posts)');
    } catch (e) {
      debugPrint('[HomeController] ❌ Refresh failed: $e');
      if (_previousPosts.isNotEmpty) {
        posts.value = _previousPosts;
        offset = _previousOffset;
        _seenPostUuids
          ..clear()
          ..addAll(posts.map((p) => p.uuid));
        debugPrint('[HomeController] ♻️ State restored after failure');
      }
      _previousPosts.clear();
      _previousOffset = 0;
    } finally {
      _cancelPendingFetch = false;
      _setState(FeedState.idle);
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
