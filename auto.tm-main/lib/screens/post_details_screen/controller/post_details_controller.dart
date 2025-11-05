// Removed legacy direct HTTP/json parsing imports after repository refactor
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/screens/post_details_screen/domain/image_prefetch_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
// Removed unused http & url_launcher imports after repository integration
import 'package:auto_tm/screens/post_details_screen/model/post_details_state.dart';
import 'package:auto_tm/screens/post_details_screen/domain/post_repository.dart';

class PostDetailsController extends GetxController {
  final box = GetStorage();

  var post = Rxn<Post>();
  var isLoading = true.obs;
  var currentPage = 0.obs;
  // New Phase 3 state
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


  final PostRepository _repository = PostRepository();

  Future<void> fetchProductDetails(String uuid) async {
    isLoading.value = true; // legacy flag
    state.value = const PostDetailsLoading();
    try {
      final parsed = await _repository.fetchPost(uuid);
      if (kDebugMode) {
        debugPrint('[PostDetailsController] video section raw: ${parsed.video}');
      }
      post.value = parsed;
      state.value = PostDetailsReady(parsed);

      Future.delayed(const Duration(milliseconds: 150), () {
        if (_disposed) return;
        final telemetry = CachedImageHelper.getTelemetry();
        _baselineHits = telemetry.cacheHits;
        _baselineMisses = telemetry.cacheMisses;
        _baselineSuccesses = telemetry.loadSuccesses;
        _baselineFailures = telemetry.loadFailures;

        final photos = post.value?.photos;
        if (photos != null) {
          _prefetchService.prefetchInitial(photos, disposed: _disposed);
        }
        _monitorInitialLoadPerformance();
      });
    } on RepositoryHttpException catch (e) {
      state.value = PostDetailsError(_mapError(e.message));
    } on RepositoryException catch (e) {
      state.value = PostDetailsError(_mapError(e.message));
    } catch (_) {
      state.value = PostDetailsError(_mapError('network_exception'));
    } finally {
      isLoading.value = false;
    }
  }

  /// Map low-level repository error codes to translation keys used by UI.
  String _mapError(String code) {
    switch (code) {
      case 'token_refresh_failed':
        return 'blogs_token_refresh_failed'; // reuse existing token refresh message
      case 'network_exception':
        return 'blogs_fetch_error'; // generic network fetch error wording
      default:
        if (code.startsWith('http_')) {
          // Provide more granular mapping if desired
          final status = code.substring('http_'.length);
          switch (status) {
            case '404':
              return 'common_unknown_error'; // not found for post details
            case '500':
              return 'common_unknown_error'; // server error generic
            default:
              return 'common_unknown_error';
          }
        }
        return 'common_unknown_error';
    }
  }
}
