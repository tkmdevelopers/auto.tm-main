// Phase 6 Refactor: Telemetry service extraction complete
// Removed legacy direct HTTP/json parsing imports after repository refactor
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/screens/post_details_screen/domain/image_prefetch_service.dart';
import 'package:auto_tm/screens/post_details_screen/domain/telemetry_service.dart';
import 'package:auto_tm/screens/post_details_screen/domain/auth_token_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_details_state.dart';
import 'package:auto_tm/screens/post_details_screen/domain/post_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailsController extends GetxController {
  final box = GetStorage();
  final TelemetryService _telemetry;
  final PostRepository _repository;
  final ImagePrefetchService _prefetchService;

  var currentPage = 0.obs;

  // Phase 3: Single source of truth - sealed state pattern
  final Rx<PostDetailsState> state = const PostDetailsLoading().obs;

  // Computed properties for backward compatibility during migration
  Post? get post {
    final s = state.value;
    return s is PostDetailsReady ? s.post : null;
  }

  bool get isLoading => state.value is PostDetailsLoading;

  // Phase 1: Disposal guard to prevent late prefetch calls
  bool _disposed = false;

  // Phase 4: Network sensitivity and quality adaptation
  bool _networkSlow = false;
  int _slowLoadCount = 0;

  // Constructor with dependency injection for testing
  PostDetailsController({
    TelemetryService? telemetry,
    PostRepository? repository,
    ImagePrefetchService? prefetchService,
  })  : _telemetry = telemetry ?? ImageLoadTelemetryService(),
        _repository = repository ?? PostRepository(
          tokenProvider: GetStorageAuthTokenProvider(GetStorage()),
        ),
        _prefetchService = prefetchService ?? ImagePrefetchService();

  void setCurrentPage(int index) {
    currentPage.value = index;
    final photos = post?.photos; // ✅ Using computed property
    if (photos != null) {
      _prefetchService.prefetchAdjacent(
        currentIndex: index,
        photos: photos,
        disposed: () => _disposed, // ✅ Closure prevents TOCTOU race
      );
    }
  }

  @override
  void onClose() {
    // Phase 6: Finish telemetry session
    final postUuid = post?.uuid ?? 'unknown'; // ✅ Using computed property
    _telemetry.finishSession(postUuid);

    // Phase 1: Mark as disposed to prevent late async prefetch calls
    _disposed = true;
    _prefetchService.resetSession();

    super.onClose();
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

  Future<void> fetchProductDetails(String uuid) async {
    state.value = const PostDetailsLoading();

    // ✅ Phase 6: Start telemetry BEFORE first image loads (fixes baseline contamination)
    _telemetry.startSession(uuid);

    try {
      final parsed = await _repository.fetchPost(uuid);
      if (kDebugMode) {
        debugPrint('[PostDetailsController] video section raw: ${parsed.video}');
      }

      // Check if disposed during fetch
      if (_disposed) return;

      // ✅ Single state update - no dual state management
      state.value = PostDetailsReady(parsed);

      // ✅ Prefetch immediately (no delay needed, baseline already captured)
      final photos = post?.photos; // ✅ Using computed property
      if (photos != null && !_disposed) {
        _prefetchService.prefetchInitial(photos, disposed: () => _disposed); // ✅ Closure prevents TOCTOU
        _monitorInitialLoadPerformance();
      }
    } on RepositoryHttpException catch (e) {
      if (!_disposed) {
        state.value = PostDetailsError(_mapError(e.message));
      }
    } on RepositoryException catch (e) {
      if (!_disposed) {
        state.value = PostDetailsError(_mapError(e.message));
      }
    } catch (_) {
      if (!_disposed) {
        state.value = PostDetailsError(_mapError('network_exception'));
      }
    }
  }

  /// Launch phone dialer with the given number
  Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (kDebugMode) {
        debugPrint('[PostDetailsController] Could not launch $phoneNumber');
      }
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
