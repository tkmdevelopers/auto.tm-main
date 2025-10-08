import 'package:flutter/material.dart';

/// Convenience extensions to migrate away from deprecated Color.withOpacity.
///
/// Usage examples:
///   color.alphaPct(0.12)            // 12% opacity using withValues
///   color.withAlphaPercent(30)      // 30% opacity (int percent 0-100)
///   color.opacityCompat(0.5)        // Drop‑in replacement for withOpacity
///
/// NOTE: Prefer the explicit helpers (alphaPct / withAlphaPercent) when
/// introducing new code. Keep `opacityCompat` only for staged migrations
/// where a mechanical find/replace of `.withOpacity(` -> `.opacityCompat(`
/// reduces churn and risk. Remove once all calls are moved to the helpers.
extension ColorOpacityExtensions on Color {
  /// Apply opacity using the newer Color.withValues API (alpha 0.0 - 1.0).
  Color alphaPct(double opacity) => withValues(alpha: opacity.clamp(0.0, 1.0));

  /// Apply opacity using an integer percent (0 - 100).
  Color withAlphaPercent(int percent) =>
      withValues(alpha: (percent.clamp(0, 100)) / 100.0);

  /// Transitional drop‑in replacement for deprecated withOpacity.
  /// Use only during migration; prefer [alphaPct] afterward.
  Color opacityCompat(double opacity) =>
      withValues(alpha: opacity.clamp(0.0, 1.0));
}
