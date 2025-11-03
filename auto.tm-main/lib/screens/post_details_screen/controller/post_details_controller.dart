import 'dart:convert';

import 'package:auto_tm/screens/post_details_screen/controller/video_controller.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/video_player.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PostDetailsController extends GetxController {
  final box = GetStorage();

  var post = Rxn<Post>();
  var isLoading = true.obs;
  var currentPage = 0.obs;

  // Track prefetched URLs to avoid redundant network requests
  final Set<String> _prefetchedUrls = {};

  // Phase 1: Disposal guard to prevent late prefetch calls
  bool _disposed = false;

  // Phase 2: Adaptive prefetch tracking
  int _lastPrefetchIndex = -1;
  int _consecutiveForwardSwipes = 0;
  DateTime? _lastSwipeTime;

  // Phase 3: Session telemetry baseline for delta calculation
  DateTime? _sessionStart;
  int _baselineHits = 0;
  int _baselineMisses = 0;
  int _baselineSuccesses = 0;
  int _baselineFailures = 0;

  // Phase 4: Network sensitivity and quality adaptation
  bool _networkSlow = false;
  int _slowLoadCount = 0;

  @override
  void onInit() {
    super.onInit();
    // Fix #10: Session start time marked here, but baseline captured after first image loads
    // to avoid contamination from home screen prefetch
    _sessionStart = DateTime.now();

    if (kDebugMode) {
      debugPrint(
        '[PostDetailsController] 📊 Phase 3: Session started, baseline will be captured after first image',
      );
    }
  }

  void setCurrentPage(int index) {
    currentPage.value = index;
    // Prefetch adjacent images when page changes (Phase 1 optimization)
    _prefetchAdjacentImages(index);
  }

  @override
  void onClose() {
    // Phase 3: Log session telemetry delta before cleanup
    _logSessionTelemetry();

    // Phase 1: Mark as disposed to prevent late async prefetch calls
    _disposed = true;
    _prefetchedUrls.clear();

    // Phase 2: Reset adaptive tracking state
    _lastPrefetchIndex = -1;
    _consecutiveForwardSwipes = 0;
    _lastSwipeTime = null;

    super.onClose();
  }

  /// Phase 3: Log telemetry delta for this post details session
  /// Helps identify performance gaps and validate prefetch effectiveness
  void _logSessionTelemetry() {
    if (_sessionStart == null) return;

    final telemetry = CachedImageHelper.getTelemetry();
    final sessionDuration = DateTime.now().difference(_sessionStart!);

    // Calculate deltas for this session
    final sessionHits = telemetry.cacheHits - _baselineHits;
    final sessionMisses = telemetry.cacheMisses - _baselineMisses;
    final sessionSuccesses = telemetry.loadSuccesses - _baselineSuccesses;
    final sessionFailures = telemetry.loadFailures - _baselineFailures;
    final totalRequests = sessionHits + sessionMisses;
    final hitRate = totalRequests > 0
        ? (sessionHits / totalRequests * 100)
        : 0.0;
    final successRate = (sessionSuccesses + sessionFailures) > 0
        ? (sessionSuccesses / (sessionSuccesses + sessionFailures) * 100)
        : 0.0;

    // Count slow loads in this session (approximation based on global list)
    final slowThreshold = 600; // ms
    final slowCount = telemetry.loadTimesMs
        .where((t) => t >= slowThreshold)
        .length;

    if (kDebugMode) {
      final postUuid = post.value?.uuid ?? 'unknown';
      debugPrint(
        '[PostDetailsTelemetry] 📊 Session Summary:\n'
        '  Post: $postUuid\n'
        '  Duration: ${sessionDuration.inSeconds}s\n'
        '  Cache: hits=$sessionHits misses=$sessionMisses hitRate=${hitRate.toStringAsFixed(1)}%\n'
        '  Network: success=$sessionSuccesses fail=$sessionFailures successRate=${successRate.toStringAsFixed(1)}%\n'
        '  Slow Loads (>$slowThreshold ms): $slowCount\n'
        '  Avg Load Time: ${telemetry.averageLoadTimeMs.toStringAsFixed(0)}ms',
      );
    }
  }

  /// Phase 4: Monitor network performance and adjust prefetch strategy
  /// Tracks consecutive slow loads to detect poor network conditions
  void _monitorNetworkPerformance(int loadTimeMs) {
    const slowThreshold = 800; // ms

    // Fix #7: Add network recovery logic
    const fastThreshold = 500; // ms - threshold for good network performance

    if (loadTimeMs >= slowThreshold) {
      _slowLoadCount++;

      // Mark network as slow after 2 consecutive slow loads
      if (_slowLoadCount >= 2 && !_networkSlow) {
        _networkSlow = true;
        if (kDebugMode) {
          debugPrint(
            '[PostDetailsController] 🐌 Phase 4: Network detected as slow, reducing prefetch aggressiveness',
          );
        }
      }
    } else if (loadTimeMs < fastThreshold) {
      // Fix #7: Decrement counter on fast load to enable recovery
      if (_slowLoadCount > 0) {
        _slowLoadCount--;
      }

      // Fix #7: Clear slow flag after 2 consecutive fast loads
      if (_networkSlow && _slowLoadCount == 0) {
        _networkSlow = false;
        if (kDebugMode) {
          debugPrint(
            '[PostDetailsController] 🚀 Phase 4: Network speed recovered, restoring normal prefetch',
          );
        }
      }
    } else {
      // Neutral zone (500-800ms): maintain current state
      // Don't increment or decrement counter
    }
  }

  /// Phase 4: Monitor initial image load to detect network conditions early
  /// Uses telemetry to sample recent load times and set network flag
  void _monitorInitialLoadPerformance() {
    // Delay check slightly to allow first image(s) to load
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_disposed) return;

      final telemetry = CachedImageHelper.getTelemetry();

      // Sample recent load times (last 3 loads)
      if (telemetry.loadTimesMs.length >= 3) {
        final recentLoads = telemetry.loadTimesMs
            .skip(telemetry.loadTimesMs.length - 3)
            .toList();

        final avgRecentLoad =
            recentLoads.reduce((a, b) => a + b) / recentLoads.length;

        // Monitor performance to detect slow network early
        _monitorNetworkPerformance(avgRecentLoad.toInt());
      }
    });
  }

  /// Phase 1: Batch prefetch adjacent images for instant carousel navigation
  /// Uses CachedImageHelper.prewarmCache for parallel batch prefetch
  /// Starts from index 1 (carousel loads index 0 naturally)
  /// Configurable warm count (default 5 to cover first few swipes)
  /// Phase 4: Adapts to network conditions (reduces count on slow network)
  void _prefetchInitialImages() {
    // Guard against post-disposal async work
    if (_disposed) return;

    final photos = post.value?.photos;
    if (photos == null || photos.isEmpty) return;

    // Phase 4: Reduce initial warm count on slow networks
    const normalWarmCount = 5;
    const slowNetworkWarmCount = 3;
    final initialWarmCount = _networkSlow
        ? slowNetworkWarmCount
        : normalWarmCount;

    final warmCount = photos.length > initialWarmCount
        ? initialWarmCount
        : photos.length;

    // Collect URLs to batch prefetch
    // CRITICAL FIX: Start from index 1, not 0 (carousel loads 0 naturally)
    final urlsToPrefetch = <String>[];
    for (int i = 1; i < warmCount; i++) {  // Changed from i = 0 to i = 1
      final photoPath = photos[i].bestPath;
      if (photoPath.isEmpty) continue;

      final imageUrl = CachedImageHelper.buildUrlForPrefetch(
        photoPath,
        ApiKey.ip,
      );

      // Skip if already prefetched in this session
      if (_prefetchedUrls.contains(imageUrl)) continue;

      urlsToPrefetch.add(imageUrl);
      _prefetchedUrls.add(imageUrl);
    }

    // Phase 1: Batch prefetch using prewarmCache for parallel efficiency
    // Phase 4: Use longer timeout for post details (15s) since user is actively viewing
    if (urlsToPrefetch.isNotEmpty) {
      CachedImageHelper.prewarmCache(
        urlsToPrefetch,
        timeout: const Duration(seconds: 15),
      );

      if (kDebugMode) {
        debugPrint(
          '[PostDetailsController] 🚚 Phase 1: Batch prefetch ${urlsToPrefetch.length} initial images',
        );
      }
    }
  }

  /// Phase 2: Adaptive direction-aware prefetch with dynamic radius
  /// Intelligently expands prefetch window based on:
  /// - Swipe velocity (fast consecutive swipes trigger wider radius)
  /// - Direction consistency (forward streak biases forward prefetch)
  /// - Bounds checking to prevent out-of-range access
  void _prefetchAdjacentImages(int currentIndex) {
    // Phase 1: Guard against post-disposal async work
    if (_disposed) return;

    // Fix #6: Prevent duplicate prefetch on same index
    if (_lastPrefetchIndex == currentIndex) return;

    final photos = post.value?.photos;
    if (photos == null || photos.isEmpty) return;

    // Phase 2: Track swipe direction and velocity
    final now = DateTime.now();
    final isForward = currentIndex > _lastPrefetchIndex;
    final timeDelta = _lastSwipeTime != null
        ? now.difference(_lastSwipeTime!).inMilliseconds
        : 999;

    // Update forward streak counter
    if (isForward && _lastPrefetchIndex >= 0) {
      _consecutiveForwardSwipes++;
    } else if (!isForward && _lastPrefetchIndex >= 0) {
      _consecutiveForwardSwipes = 0;
    }

    // Phase 2: Determine adaptive radius based on velocity and direction
    // Fast swipe = <300ms between pages, triggers expanded radius
    final isFastSwipe = timeDelta < 300;
    final hasForwardMomentum = _consecutiveForwardSwipes >= 2;

    // Adaptive radius calculation
    int forwardRadius = 1;
    int backwardRadius = 1;

    if (hasForwardMomentum && isFastSwipe) {
      // Strong forward momentum: prefetch 3 ahead, 1 behind
      forwardRadius = 3;
      backwardRadius = 1;
    } else if (isFastSwipe) {
      // Fast but no clear direction: prefetch 2 in each direction
      forwardRadius = 2;
      backwardRadius = 2;
    } else if (hasForwardMomentum) {
      // Forward momentum but slower: prefetch 2 ahead, 1 behind
      forwardRadius = 2;
      backwardRadius = 1;
    }
    // else: default ±1 (slow, no momentum)

    // Fix #5: Phase 4 - Reduce radius on slow networks but respect momentum
    // Cap at 2 for momentum users instead of hard dividing by 2
    if (_networkSlow) {
      if (hasForwardMomentum) {
        // Keep some predictive benefit for momentum users
        forwardRadius = forwardRadius > 2 ? 2 : forwardRadius;
        backwardRadius = 1; // Always 1 behind on slow network
      } else {
        // No momentum: use conservative reduction
        forwardRadius = (forwardRadius / 2).ceil();
        backwardRadius = (backwardRadius / 2).ceil();
        if (forwardRadius < 1) forwardRadius = 1;
        if (backwardRadius < 1) backwardRadius = 1;
      }
    }

    // Phase 2: Collect target indices within adaptive radius
    final targetIndices = <int>{};

    // Forward prefetch
    for (int i = 1; i <= forwardRadius; i++) {
      final targetIndex = currentIndex + i;
      if (targetIndex < photos.length) {
        targetIndices.add(targetIndex);
      }
    }

    // Backward prefetch
    for (int i = 1; i <= backwardRadius; i++) {
      final targetIndex = currentIndex - i;
      if (targetIndex >= 0) {
        targetIndices.add(targetIndex);
      }
    }

    // Fix #9: Clear stale URLs beyond active window to prevent unbounded growth
    // Keep only URLs within ±10 indices of current position (max ~50 URLs)
    if (_prefetchedUrls.length > 50) {
      final relevantIndices = <int>{};
      for (int i = currentIndex - 10; i <= currentIndex + 10; i++) {
        if (i >= 0 && i < photos.length) {
          relevantIndices.add(i);
        }
      }

      final relevantUrls = <String>{};
      for (final index in relevantIndices) {
        final photoPath = photos[index].bestPath;
        if (photoPath.isNotEmpty) {
          relevantUrls.add(
            CachedImageHelper.buildUrlForPrefetch(photoPath, ApiKey.ip),
          );
        }
      }

      // Replace set with only relevant URLs
      _prefetchedUrls.clear();
      _prefetchedUrls.addAll(relevantUrls);
    }

    // Phase 2: Build URL list for batch prefetch
    final urlsToPrefetch = <String>[];
    for (final index in targetIndices) {
      final photoPath = photos[index].bestPath;
      if (photoPath.isEmpty) continue;

      final imageUrl = CachedImageHelper.buildUrlForPrefetch(
        photoPath,
        ApiKey.ip,
      );

      // Skip if already prefetched
      if (_prefetchedUrls.contains(imageUrl)) continue;

      urlsToPrefetch.add(imageUrl);
      _prefetchedUrls.add(imageUrl);
    }

    // Phase 2: Batch prefetch adjacent images
    // Phase 4: Use longer timeout (15s) for critical adjacent images
    if (urlsToPrefetch.isNotEmpty) {
      CachedImageHelper.prewarmCache(
        urlsToPrefetch,
        timeout: const Duration(seconds: 15),
      );

      if (kDebugMode) {
        debugPrint(
          '[PostDetailsController] 🚀 Phase 2: Adaptive prefetch ${urlsToPrefetch.length} images '
          '(forward: $forwardRadius, backward: $backwardRadius, '
          'streak: $_consecutiveForwardSwipes, fast: $isFastSwipe)',
        );
      }
    }

    // Update tracking state
    _lastPrefetchIndex = currentIndex;
    _lastSwipeTime = now;
  }

  final RxBool isPlaying = false.obs;
  final String apiKeyIp = ApiKey.ip;
  // VideoPlayerController? _videoPlayerController;
  // List<String> _orderedUrls = [];
  // int _currentVideoIndex = 0;

  Future<void> fetchProductDetails(String uuid) async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiKey.getPostDetailsKey}$uuid?model=true&brand=true&photo=true',
        ),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          final videoSection = data['video'];
          debugPrint(
            '[PostDetailsController] video section raw: $videoSection',
          );
        }
        post.value = Post.fromJson(data);
        if (kDebugMode)
          debugPrint(
            '[PostDetailsController] parsed post video: ${post.value?.video}',
          );

        // CRITICAL FIX: Start prefetch immediately after data available
        // The carousel will load image 0 naturally, so we focus on 1-4
        // Short delay (150ms) ensures image 0 starts loading first
        Future.delayed(const Duration(milliseconds: 150), () {
          if (_disposed) return;

          // Fix #10: Capture baseline AFTER first image loads for accurate session metrics
          final telemetry = CachedImageHelper.getTelemetry();
          _baselineHits = telemetry.cacheHits;
          _baselineMisses = telemetry.cacheMisses;
          _baselineSuccesses = telemetry.loadSuccesses;
          _baselineFailures = telemetry.loadFailures;

          // Prefetch adjacent images (1-4) for smooth initial carousel experience
          // Image 0 loads naturally from carousel, no need to prefetch it
          _prefetchInitialImages();

          // Phase 4: Monitor initial load performance for network detection
          _monitorInitialLoadPerformance();
        });
      }
      if (response.statusCode == 406) {
        // await refreshAccesToken(uuid); // ✅ Pass the uuid here
      }
    } catch (e) {
      return;
    } finally {
      isLoading.value = false;
    }
  }

  // Future<void> refreshAccesToken(String uuid) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse(ApiKey.refreshTokenKey),
  //       headers: {
  //         "Content-Type": "application/json",
  //         'Authorization': 'Bearer ${box.read('REFRESH_TOKEN')}'
  //       },
  //     );
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final newAccessToken = data['accessToken'];
  //       box.write('ACCESS_TOKEN', newAccessToken);

  //       await fetchProductDetails(uuid); // ✅ Safe retry
  //     }
  //   } catch (e) {
  //     print('Token refresh failed: $e');
  //   }
  // }
  Future<void> refreshAccesToken(String uuid) async {
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
          await fetchProductDetails(uuid);
        } else {}
      } else {}
    } catch (e) {
      return;
    }
  }

  void makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {}
  }

  void showVideoPage(Video video) {
    if (video.url != null && video.url!.isNotEmpty) {
      List<String> orderedUrls = List.from(
        video.url!,
      ).map((url) => '$apiKeyIp$url').toList();
      if (video.partNumber != null) {
        orderedUrls.sort((a, b) {
          final partA =
              int.tryParse(a.split('_part').last.replaceAll('.mp4', '')) ?? 0;
          final partB =
              int.tryParse(b.split('_part').last.replaceAll('.mp4', '')) ?? 0;
          return partB.compareTo(partA); // Обратный порядок
        });
      } else {
        orderedUrls = orderedUrls.reversed.toList();
      }
      Get.to(
        () => VideoPlayerPage(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => FullVideoPlayerController());
        }),
        arguments: orderedUrls,
      );
    } else {
      ('Ошибка', 'Нет URL-адресов для воспроизведения видео');
    }
  }
}
