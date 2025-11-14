import 'package:flutter/foundation.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';

/// Abstract telemetry service for tracking image loading performance.
/// Provides session-scoped metrics to avoid contamination from other screens.
abstract class TelemetryService {
  /// Start a new telemetry session for the given post UUID.
  /// Captures baseline metrics before any images load.
  void startSession(String postUuid);

  /// Finish the session and log final metrics.
  /// Calculates deltas from baseline to show session-specific performance.
  void finishSession(String postUuid);

  /// Record an image load event (future enhancement for session-scoped tracking).
  void recordImageLoad({
    required String url,
    required int loadTimeMs,
    required bool cacheHit,
    required bool success,
  });
}

/// Production implementation using CachedImageHelper telemetry.
/// Tracks session-specific metrics by capturing baseline at session start.
class ImageLoadTelemetryService implements TelemetryService {
  final Map<String, _SessionData> _sessions = {};

  @override
  void startSession(String postUuid) {
    // ✅ Capture baseline IMMEDIATELY before any image loads
    // This prevents contamination from home screen or other concurrent sessions
    final globalTelemetry = CachedImageHelper.getTelemetry();

    _sessions[postUuid] = _SessionData(
      sessionId: postUuid,
      startTime: DateTime.now(),
      baselineHits: globalTelemetry.cacheHits,
      baselineMisses: globalTelemetry.cacheMisses,
      baselineSuccesses: globalTelemetry.loadSuccesses,
      baselineFailures: globalTelemetry.loadFailures,
    );

    if (kDebugMode) {
      debugPrint('[TelemetryService] 📊 Session started: $postUuid');
      debugPrint(
        '  Baseline captured: hits=${globalTelemetry.cacheHits} misses=${globalTelemetry.cacheMisses}',
      );
    }
  }

  @override
  void finishSession(String postUuid) {
    final session = _sessions[postUuid];
    if (session == null) {
      if (kDebugMode) {
        debugPrint('[TelemetryService] ⚠️ No session found for $postUuid');
      }
      return;
    }

    final globalTelemetry = CachedImageHelper.getTelemetry();
    final duration = DateTime.now().difference(session.startTime);

    // Calculate deltas (session-specific metrics)
    final sessionHits = globalTelemetry.cacheHits - session.baselineHits;
    final sessionMisses = globalTelemetry.cacheMisses - session.baselineMisses;
    final sessionSuccesses =
        globalTelemetry.loadSuccesses - session.baselineSuccesses;
    final sessionFailures =
        globalTelemetry.loadFailures - session.baselineFailures;

    final totalRequests = sessionHits + sessionMisses;
    final hitRate =
        totalRequests > 0 ? (sessionHits / totalRequests * 100) : 0.0;

    final totalLoads = sessionSuccesses + sessionFailures;
    final successRate =
        totalLoads > 0 ? (sessionSuccesses / totalLoads * 100) : 0.0;

    // Count slow loads (>600ms) from global list
    // NOTE: This is approximate since we can't filter by session with current CachedImageHelper
    const slowThreshold = 600;
    final slowCount = globalTelemetry.loadTimesMs
        .where((t) => t >= slowThreshold)
        .length;

    if (kDebugMode) {
      debugPrint(
        '[TelemetryService] 📊 Session Summary ($postUuid):\n'
        '  Duration: ${duration.inSeconds}s\n'
        '  Cache: hits=$sessionHits misses=$sessionMisses hitRate=${hitRate.toStringAsFixed(1)}%\n'
        '  Network: success=$sessionSuccesses fail=$sessionFailures successRate=${successRate.toStringAsFixed(1)}%\n'
        '  Slow Loads (>$slowThreshold ms): $slowCount (approximate, includes global)\n'
        '  Global Avg Load Time: ${globalTelemetry.averageLoadTimeMs.toStringAsFixed(0)}ms',
      );
    }

    // Clean up session
    _sessions.remove(postUuid);
  }

  @override
  void recordImageLoad({
    required String url,
    required int loadTimeMs,
    required bool cacheHit,
    required bool success,
  }) {
    // Currently CachedImageHelper tracks this automatically
    // This method is reserved for future session-scoped tracking enhancement
    // where each session maintains its own metrics independent of global state
  }
}

/// No-op implementation for testing or production builds without telemetry.
/// Useful for:
/// - Unit tests (no logging spam)
/// - Production builds where telemetry is disabled
/// - Performance testing without overhead
class NoOpTelemetryService implements TelemetryService {
  const NoOpTelemetryService();

  @override
  void startSession(String postUuid) {
    // No-op
  }

  @override
  void finishSession(String postUuid) {
    // No-op
  }

  @override
  void recordImageLoad({
    required String url,
    required int loadTimeMs,
    required bool cacheHit,
    required bool success,
  }) {
    // No-op
  }
}

/// Internal session data tracking.
/// Stores baseline metrics captured at session start for delta calculation.
class _SessionData {
  final String sessionId;
  final DateTime startTime;
  final int baselineHits;
  final int baselineMisses;
  final int baselineSuccesses;
  final int baselineFailures;

  _SessionData({
    required this.sessionId,
    required this.startTime,
    required this.baselineHits,
    required this.baselineMisses,
    required this.baselineSuccesses,
    required this.baselineFailures,
  });
}
