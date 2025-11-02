import 'package:get/get.dart';

/// Consolidated helpers for applying upload progress math.
/// Reduces duplication inside controller upload parts.
class UploadProgress {
  /// Applies delta calculation and ratio update for a resource (photo/video).
  /// [sent] is current cumulative sent bytes from onSendProgress.
  /// [lastSent] is a mutable int (boxed in RxInt or external holder) representing previous sent bytes.
  /// Returns updated lastSent value.
  static int applyProgress({
    required int sent,
    required int lastSent,
    required RxInt sentAccumulator,
    required RxInt totalBytes,
    required RxDouble progressRatio,
  }) {
    final delta = sent - lastSent;
    if (delta > 0) {
      sentAccumulator.value += delta;
      if (totalBytes.value > 0) {
        final ratio = (sentAccumulator.value / totalBytes.value)
            .clamp(0, 1)
            .toDouble();
        progressRatio.value = ratio;
      }
    }
    return sent;
  }
}
