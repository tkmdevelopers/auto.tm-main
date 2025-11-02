import 'dart:io' show ProcessInfo;
import 'package:flutter/foundation.dart';

/// Phase E: Memory profiling utility for upload flow optimization
///
/// Tracks memory usage during photo encoding and uploads to validate
/// lazy encoding improvements.
///
/// Note: Memory tracking is approximate and platform-dependent.
/// Use for relative comparisons, not absolute measurements.
class MemoryProfiler {
  static const bool _enabled = kDebugMode;
  static final Map<String, _MemorySnapshot> _snapshots = {};

  /// Mark a memory checkpoint with a label
  static void mark(String label) {
    if (!_enabled) return;

    try {
      // Get current resident memory (RSS) from process info
      // This is a rough estimate but works across platforms
      final rss = ProcessInfo.currentRss;
      final timestamp = DateTime.now();

      _snapshots[label] = _MemorySnapshot(
        label: label,
        timestamp: timestamp,
        residentSetSize: rss,
      );

      _log('MARK', label, 'RSS: ${_formatBytes(rss)}');
    } catch (_) {
      // Silent fail - memory profiling is best-effort
    }
  }

  /// Calculate delta between two checkpoints
  static String delta(String fromLabel, String toLabel) {
    if (!_enabled) return '';

    try {
      final from = _snapshots[fromLabel];
      final to = _snapshots[toLabel];

      if (from == null || to == null) {
        return 'Missing snapshots: from=$fromLabel to=$toLabel';
      }

      final rssDelta = to.residentSetSize - from.residentSetSize;
      final timeDelta = to.timestamp.difference(from.timestamp);

      final result =
          'Δ RSS: ${_formatBytes(rssDelta)} | Time: ${timeDelta.inMilliseconds}ms';

      _log('DELTA', '$fromLabel → $toLabel', result);
      return result;
    } catch (_) {
      return 'Error calculating delta';
    }
  }

  /// Clear all snapshots
  static void clear() {
    _snapshots.clear();
  }

  /// Get summary of all snapshots
  static String summary() {
    if (!_enabled || _snapshots.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('=== Memory Profile Summary ===');

    final sorted = _snapshots.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final snap in sorted) {
      buffer.writeln(
        '${snap.label}: RSS=${_formatBytes(snap.residentSetSize)}',
      );
    }

    if (sorted.length >= 2) {
      final first = sorted.first;
      final last = sorted.last;
      final totalRssDelta = last.residentSetSize - first.residentSetSize;
      buffer.writeln(
        'Total Memory Growth: ${_formatBytes(totalRssDelta)} over ${last.timestamp.difference(first.timestamp).inSeconds}s',
      );
    }

    return buffer.toString();
  }

  static String _formatBytes(int bytes) {
    if (bytes < 0) return '-${_formatBytes(-bytes)}';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static void _log(String level, String label, String message) {
    if (!_enabled) return;
    debugPrint('[MemoryProfiler] [$level] $label: $message');
  }
}

class _MemorySnapshot {
  final String label;
  final DateTime timestamp;
  final int residentSetSize;

  _MemorySnapshot({
    required this.label,
    required this.timestamp,
    required this.residentSetSize,
  });
}
