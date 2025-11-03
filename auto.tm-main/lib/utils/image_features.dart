/// Image optimization feature flags (dev/runtime toggles)
/// These can later be wired to remote config / debug settings screen.
class ImageFeatures {
  /// Use bucketed aspect ratio for feed cards to improve cache reuse.
  /// When false, uses precise aspect ratio.
  static const bool useBucketedFeedAspectRatio = true; // Phase 3 finalization

  /// Enable periodic telemetry logging (already controlled in HomeController).
  static const bool periodicTelemetryLogging = true;
}
