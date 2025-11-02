import 'package:flutter/foundation.dart';

/// Structured logger for upload operations with task correlation.
/// Provides consistent logging format for debugging and monitoring upload flows.
class UploadLogger {
  UploadLogger._();

  static const String _tag = '[UploadFlow]';

  /// Log the start of an upload part (video or photo).
  /// [taskId] - Unique identifier for the upload task
  /// [partType] - Type of media being uploaded ('video' or 'photo')
  /// [partIndex] - Index of the part (0 for video, photo index for photos)
  /// [postUuid] - Post UUID being uploaded to
  /// [sizeBytes] - Size of the media part in bytes
  static void logPartStart({
    required String taskId,
    required String partType,
    required int partIndex,
    required String postUuid,
    required int sizeBytes,
  }) {
    if (kDebugMode) {
      print(
        '$_tag [START] taskId=$taskId partType=$partType '
        'partIndex=$partIndex postUuid=$postUuid sizeBytes=$sizeBytes',
      );
    }
  }

  /// Log progress updates during upload.
  /// [taskId] - Unique identifier for the upload task
  /// [partType] - Type of media being uploaded
  /// [partIndex] - Index of the part
  /// [sent] - Bytes sent so far
  /// [total] - Total bytes to send
  static void logPartProgress({
    required String taskId,
    required String partType,
    required int partIndex,
    required int sent,
    required int total,
  }) {
    // Only log at significant milestones to avoid log spam
    final percent = total > 0 ? (sent / total * 100).toInt() : 0;
    if (percent % 25 == 0 || sent == total) {
      if (kDebugMode) {
        print(
          '$_tag [PROGRESS] taskId=$taskId partType=$partType '
          'partIndex=$partIndex sent=$sent total=$total progress=$percent%',
        );
      }
    }
  }

  /// Log successful completion of an upload part.
  /// [taskId] - Unique identifier for the upload task
  /// [partType] - Type of media uploaded
  /// [partIndex] - Index of the part
  /// [sizeBytes] - Total bytes uploaded
  /// [durationMs] - Time taken in milliseconds
  static void logPartComplete({
    required String taskId,
    required String partType,
    required int partIndex,
    required int sizeBytes,
    int? durationMs,
  }) {
    if (kDebugMode) {
      final duration = durationMs != null ? ' duration=${durationMs}ms' : '';
      print(
        '$_tag [COMPLETE] taskId=$taskId partType=$partType '
        'partIndex=$partIndex sizeBytes=$sizeBytes$duration',
      );
    }
  }

  /// Log upload failure with error details.
  /// [taskId] - Unique identifier for the upload task
  /// [partType] - Type of media that failed
  /// [partIndex] - Index of the part that failed
  /// [error] - Error message or description
  /// [statusCode] - HTTP status code if available
  static void logFailure({
    required String taskId,
    required String partType,
    required int partIndex,
    required String error,
    int? statusCode,
  }) {
    if (kDebugMode) {
      final status = statusCode != null ? ' status=$statusCode' : '';
      print(
        '$_tag [FAILURE] taskId=$taskId partType=$partType '
        'partIndex=$partIndex error=$error$status',
      );
    }
  }

  /// Log pipeline phase transitions.
  /// [taskId] - Unique identifier for the upload task
  /// [phase] - Phase name (e.g., 'create', 'media', 'finalize')
  /// [status] - Status message
  static void logPhase({
    required String taskId,
    required String phase,
    required String status,
  }) {
    if (kDebugMode) {
      print('$_tag [PHASE] taskId=$taskId phase=$phase status=$status');
    }
  }

  /// Log task-level events (start, retry, complete, cancel).
  /// [taskId] - Unique identifier for the upload task
  /// [event] - Event type (e.g., 'TASK_START', 'TASK_RETRY', 'TASK_COMPLETE')
  /// [details] - Additional details about the event
  static void logTask({
    required String taskId,
    required String event,
    String? details,
  }) {
    if (kDebugMode) {
      final detailsStr = details != null ? ' details=$details' : '';
      print('$_tag [TASK] taskId=$taskId event=$event$detailsStr');
    }
  }
}
