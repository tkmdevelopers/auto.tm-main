import 'dart:convert';

import 'package:auto_tm/screens/post_details_screen/controller/video_controller.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/screens/post_details_screen/domain/image_prefetch_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_details_state.dart';
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
  // Phase 3: unified state
  final Rx<PostDetailsState> state = const PostDetailsLoading().obs;

  // Phase 1: Disposal guard to prevent late prefetch calls
  bool _disposed = false;
  // Phase 2: Prefetch service extraction
  final ImagePrefetchService _prefetchService = ImagePrefetchService();

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
    final photos = post.value?.photos;
    if (photos != null) {
      _prefetchService.prefetchAdjacent(
        currentIndex: index,
        photos: photos,
        disposed: _disposed,
      );
    }
  }

  @override
  void onClose() {
    // Phase 3: Log session telemetry delta before cleanup
    _logSessionTelemetry();

    // Phase 1: Mark as disposed to prevent late async prefetch calls
    _disposed = true;
    _prefetchService.resetSession();

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
        _prefetchService.networkSlow = true; // sync to service
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
        _prefetchService.networkSlow = false; // sync recovery
        if (kDebugMode) {
          debugPrint(
            '[PostDetailsController] 🚀 Phase 4: Network speed recovered, restoring normal prefetch',
          );
        }
      }
    }
  }

  /// Monitor initial loads (sample last 3 load times after brief delay) and update network flags.
  void _monitorInitialLoadPerformance() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_disposed) return;
      final telemetry = CachedImageHelper.getTelemetry();
      if (telemetry.loadTimesMs.length >= 3) {
        final recent = telemetry.loadTimesMs
            .skip(telemetry.loadTimesMs.length - 3)
            .toList();
        final avg = recent.reduce((a, b) => a + b) / recent.length;
        _monitorNetworkPerformance(avg.toInt());
        // propagate to service (already synced inside monitorNetworkPerformance)
      }
    });
  }

  final RxBool isPlaying = false.obs;
  final String apiKeyIp = ApiKey.ip;
  // VideoPlayerController? _videoPlayerController;
  // List<String> _orderedUrls = [];
  // int _currentVideoIndex = 0;

  Future<void> fetchProductDetails(String uuid) async {
  isLoading.value = true; // legacy compatibility
  state.value = const PostDetailsLoading();
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
  state.value = PostDetailsReady(post.value!);
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
          final photos = post.value?.photos;
          if (photos != null) {
            _prefetchService.prefetchInitial(photos, disposed: _disposed);
          }

          // Phase 4: Monitor initial load performance for network detection
          _monitorInitialLoadPerformance();
        });
      }
      if (response.statusCode == 406) {
        // await refreshAccesToken(uuid); // ✅ Pass the uuid here
        state.value = const PostDetailsError('token_refresh_required');
      }
      if (response.statusCode >= 400 && response.statusCode != 406) {
        state.value = PostDetailsError('http_${response.statusCode}');
      }
    } catch (e) {
      state.value = PostDetailsError('exception');
      return;
    } finally {
      isLoading.value = false;
      if (post.value == null && state.value is! PostDetailsError) {
        state.value = const PostDetailsError('empty_post');
      }
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
