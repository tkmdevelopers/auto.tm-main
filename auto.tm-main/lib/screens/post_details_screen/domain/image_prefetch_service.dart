import 'package:flutter/foundation.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'prefetch_strategy.dart';

/// Service responsible for image prefetch operations for Post Details.
/// Encapsulates initial batch prefetch and adaptive adjacent prefetch.
class ImagePrefetchService {
  final PrefetchStrategy strategy;
  final Set<String> _prefetchedUrls = <String>{};

  // Adaptive tracking moved from controller
  int lastPrefetchIndex = -1;
  int consecutiveForwardSwipes = 0;
  DateTime? lastSwipeTime;
  bool networkSlow = false; // network condition flag
  int _slowLoadCount = 0;

  ImagePrefetchService({PrefetchStrategy? strategy})
    : strategy = strategy ?? DefaultAdaptiveStrategy();

  void resetSession() {
    _prefetchedUrls.clear();
    lastPrefetchIndex = -1;
    consecutiveForwardSwipes = 0;
    lastSwipeTime = null;
    networkSlow = false;
    _slowLoadCount = 0;
  }

  /// Initial batch prefetch: indices 1..warmCount-1 (exclude 0 which carousel loads).
  void prefetchInitial(List<Photo> photos, {required bool disposed}) {
    if (disposed || photos.isEmpty) return;

    const normalWarmCount = 5;
    const slowNetworkWarmCount = 3;
    final initialWarmCount = networkSlow
        ? slowNetworkWarmCount
        : normalWarmCount;
    final warmCount = photos.length > initialWarmCount
        ? initialWarmCount
        : photos.length;

    final urlsToPrefetch = <String>[];
    for (int i = 1; i < warmCount; i++) {
      final photoPath = photos[i].bestPath;
      if (photoPath.isEmpty) continue;
      final imageUrl = CachedImageHelper.buildUrlForPrefetch(
        photoPath,
        ApiKey.ip,
      );
      if (_prefetchedUrls.contains(imageUrl)) continue;
      urlsToPrefetch.add(imageUrl);
      _prefetchedUrls.add(imageUrl);
    }
    if (urlsToPrefetch.isNotEmpty) {
      CachedImageHelper.prewarmCache(
        urlsToPrefetch,
        timeout: const Duration(seconds: 15),
      );
      if (kDebugMode) {
        debugPrint(
          '[ImagePrefetchService] 🚚 Initial batch ${urlsToPrefetch.length} images',
        );
      }
    }
  }

  /// Adaptive adjacent prefetch delegation.
  void prefetchAdjacent({
    required int currentIndex,
    required List<Photo> photos,
    required bool disposed,
  }) {
    if (disposed || photos.isEmpty) return;
    if (lastPrefetchIndex == currentIndex) return; // duplicate guard

    final now = DateTime.now();
    final timeDelta = lastSwipeTime != null
        ? now.difference(lastSwipeTime!).inMilliseconds
        : 999;
    final isForward = currentIndex > lastPrefetchIndex;
    if (isForward && lastPrefetchIndex >= 0) {
      consecutiveForwardSwipes++;
    } else if (!isForward && lastPrefetchIndex >= 0) {
      consecutiveForwardSwipes = 0;
    }
    final ctx = PrefetchContext(
      networkSlow: networkSlow,
      consecutiveForwardSwipes: consecutiveForwardSwipes,
      isFastSwipe: timeDelta < 300,
    );

    final targets = strategy.computeTargets(
      currentIndex: currentIndex,
      lastPrefetchIndex: lastPrefetchIndex,
      photos: photos,
      ctx: ctx,
    );

    // Clear stale URLs if large
    if (_prefetchedUrls.length > 50) {
      final relevantIndices = <int>{};
      for (int i = currentIndex - 10; i <= currentIndex + 10; i++) {
        if (i >= 0 && i < photos.length) relevantIndices.add(i);
      }
      final relevantUrls = <String>{};
      for (final index in relevantIndices) {
        final path = photos[index].bestPath;
        if (path.isNotEmpty) {
          relevantUrls.add(
            CachedImageHelper.buildUrlForPrefetch(path, ApiKey.ip),
          );
        }
      }
      _prefetchedUrls
        ..clear()
        ..addAll(relevantUrls);
    }

    final urlsToPrefetch = <String>[];
    for (final index in targets) {
      final path = photos[index].bestPath;
      if (path.isEmpty) continue;
      final url = CachedImageHelper.buildUrlForPrefetch(path, ApiKey.ip);
      if (_prefetchedUrls.contains(url)) continue;
      urlsToPrefetch.add(url);
      _prefetchedUrls.add(url);
    }

    if (urlsToPrefetch.isNotEmpty) {
      CachedImageHelper.prewarmCache(
        urlsToPrefetch,
        timeout: const Duration(seconds: 15),
      );
      if (kDebugMode) {
        debugPrint(
          '[ImagePrefetchService] 🚀 Adaptive prefetch ${urlsToPrefetch.length} (targets: ${targets.join(',')})',
        );
      }
    }

    lastPrefetchIndex = currentIndex;
    lastSwipeTime = now;
  }

  /// Monitor network performance similar to original controller logic.
  void monitorNetworkPerformance(int loadTimeMs) {
    const slowThreshold = 800; // ms
    const fastThreshold = 500; // ms

    if (loadTimeMs >= slowThreshold) {
      _slowLoadCount++;
      if (_slowLoadCount >= 2 && !networkSlow) {
        networkSlow = true;
        if (kDebugMode) {
          debugPrint('[ImagePrefetchService] 🐌 Network marked slow');
        }
      }
    } else if (loadTimeMs < fastThreshold) {
      if (_slowLoadCount > 0) _slowLoadCount--;
      if (networkSlow && _slowLoadCount == 0) {
        networkSlow = false;
        if (kDebugMode) {
          debugPrint('[ImagePrefetchService] 🚀 Network recovered');
        }
      }
    }
  }
}
