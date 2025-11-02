import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/services/auth/auth_service.dart';
import 'package:auto_tm/screens/post_screen/services/upload_logger.dart';

/// Represents the result of an upload operation (video or photo part)
class UploadPartResult {
  final bool success;
  final String? error;
  final int sentBytesDelta; // Bytes sent during this call

  const UploadPartResult({
    required this.success,
    this.error,
    this.sentBytesDelta = 0,
  });
}

/// Error classification
class UploadError implements Exception {
  final String message;
  final int? statusCode;
  UploadError(this.message, {this.statusCode});
  @override
  String toString() =>
      statusCode != null ? '$message (status=$statusCode)' : message;
}

/// Abstraction for multi-part media uploads related to a post.
/// Responsibilities:
/// - Perform authenticated multipart requests (video + photos)
/// - Track per-request progress and expose byte deltas to caller
/// - Provide cancellation via internal CancelToken
/// - Surface typed errors rather than swallowing
class UploadService extends GetxService {
  GetStorage? _box; // lazily initialized
  final String Function()? _tokenProvider;

  UploadService({String Function()? tokenProvider})
    : _tokenProvider = tokenProvider;
  dio.CancelToken? _activeCancelToken;

  dio.Dio _buildClient({
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(minutes: 2),
  }) {
    final token = _tokenProvider != null
        ? _tokenProvider()
        : (_box ??= GetStorage()).read('ACCESS_TOKEN');
    return dio.Dio(
      dio.BaseOptions(
        headers: {'Authorization': token != null ? 'Bearer $token' : ''},
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
  }

  /// Expose current active cancel token (read-only) for external inspection.
  dio.CancelToken? get activeCancelToken => _activeCancelToken;

  /// Cancel current active upload request (video or photo)
  void cancelActive([String reason = 'User cancelled']) {
    final token = _activeCancelToken;
    if (token == null || token.isCancelled) return;
    try {
      token.cancel(reason);
    } catch (_) {}
  }

  String _truncateBody(dynamic body) {
    if (body == null) return '';
    final s = body.toString();
    if (s.length <= 180) return s;
    return s.substring(0, 177) + '…';
  }

  UploadPartResult _errorResult({
    required String base,
    dynamic body,
    int? status,
    int sentBytes = 0,
  }) {
    final statusPart = status != null ? ' (status=$status)' : '';
    final bodyPart = body != null ? ': ${_truncateBody(body)}' : '';
    return UploadPartResult(
      success: false,
      error: '$base$statusPart$bodyPart',
      sentBytesDelta: sentBytes,
    );
  }

  /// Derive a canonical string label from a numeric aspect ratio.
  /// Uses tolerance matching against common ratios; falls back to formatted value.
  String _deriveAspectRatioLabel(double ratio) {
    const tolerance = 0.04; // allow slight floating variance
    const known = <String, double>{
      '16:9': 16 / 9,
      '4:3': 4 / 3,
      '1:1': 1.0,
      '9:16': 9 / 16,
      '3:4': 3 / 4,
    };
    for (final entry in known.entries) {
      if ((ratio - entry.value).abs() <= tolerance) return entry.key;
    }
    // Format custom ratio with two decimals (e.g., 1.78)
    return ratio.toStringAsFixed(2);
  }

  /// Wrapper to execute upload with automatic token refresh on 401/406.
  /// Attempts refresh once; if successful, retries action.
  Future<T> _withTokenRefresh<T>(
    Future<T> Function() action, {
    required T Function(String error) onAuthFailed,
  }) async {
    try {
      return await action();
    } on dio.DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 406) {
        // Attempt token refresh
        if (Get.isRegistered<AuthService>()) {
          try {
            final session = await AuthService.to.refreshTokens();
            if (session != null && !dio.CancelToken.isCancel(e)) {
              // Retry action once with new token
              return await action();
            }
          } catch (_) {
            // Refresh failed; fall through to return auth error
          }
        }
        return onAuthFailed('Authentication expired');
      }
      rethrow; // Not auth error; propagate
    }
  }

  /// Upload video file for given post UUID.
  /// [taskId] - Task correlation ID for logging and backend tracking.
  /// [onProgress] receives (sent, total, deltaSent).
  Future<UploadPartResult> uploadVideo({
    required String postUuid,
    required File file,
    String? taskId,
    void Function(int sent, int total, int delta)? onProgress,
  }) async {
    if (!file.existsSync()) {
      return const UploadPartResult(
        success: true,
      ); // treat missing file as noop success
    }

    return _withTokenRefresh(
      () => _uploadVideoInternal(postUuid, file, taskId, onProgress),
      onAuthFailed: (error) => UploadPartResult(success: false, error: error),
    );
  }

  Future<UploadPartResult> _uploadVideoInternal(
    String postUuid,
    File file,
    String? taskId,
    void Function(int sent, int total, int delta)? onProgress,
  ) async {
    final sizeBytes = file.lengthSync();
    final startTime = DateTime.now();

    // Phase C: Log upload start
    if (taskId != null) {
      UploadLogger.logPartStart(
        taskId: taskId,
        partType: 'video',
        partIndex: 0,
        postUuid: postUuid,
        sizeBytes: sizeBytes,
      );
    }

    final client = _buildClient();
    _activeCancelToken = dio.CancelToken();
    int lastSent = 0;

    final form = dio.FormData.fromMap({
      'postId': postUuid,
      'uuid': postUuid,
      'file': await dio.MultipartFile.fromFile(
        file.path,
        filename: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      ),
    });

    // 🔍 PHASE 0 DIAGNOSTIC: Log request details
    if (kDebugMode) {
      debugPrint('[Phase0][Video] POST ${ApiKey.videoUploadKey}');
      debugPrint(
        '[Phase0][Video] taskId=$taskId postUuid=$postUuid size=${sizeBytes}b',
      );
      debugPrint(
        '[Phase0][Video] formKeys=${form.fields.map((e) => e.key).toList()}',
      );
      final authHeader = client.options.headers['Authorization'];
      debugPrint(
        '[Phase0][Video] Authorization=${authHeader?.substring(0, min(30, authHeader.length ?? 0))}...',
      );
    }

    try {
      // Phase C: Add correlation header
      final options = dio.Options(
        headers: taskId != null ? {'X-Upload-Task': taskId} : null,
      );

      final resp = await client.post(
        ApiKey.videoUploadKey,
        data: form,
        options: options,
        cancelToken: _activeCancelToken,
        onSendProgress: (sent, total) {
          if (_activeCancelToken?.isCancelled == true) return;
          final previous = lastSent;
          lastSent = sent;
          final delta = sent - previous;
          if (delta > 0) {
            onProgress?.call(sent, total, delta);
            // Phase C: Log progress
            if (taskId != null) {
              UploadLogger.logPartProgress(
                taskId: taskId,
                partType: 'video',
                partIndex: 0,
                sent: sent,
                total: total,
              );
            }
          }
        },
      );
      final code = resp.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        // Phase C: Log failure
        if (taskId != null) {
          UploadLogger.logFailure(
            taskId: taskId,
            partType: 'video',
            partIndex: 0,
            error: 'Non-2xx status',
            statusCode: code,
          );
        }
        return _errorResult(
          base: 'Video upload failed',
          body: resp.data,
          status: code,
          sentBytes: lastSent,
        );
      }

      // Phase C: Log completion
      if (taskId != null) {
        final durationMs = DateTime.now().difference(startTime).inMilliseconds;
        UploadLogger.logPartComplete(
          taskId: taskId,
          partType: 'video',
          partIndex: 0,
          sizeBytes: lastSent,
          durationMs: durationMs,
        );
      }

      return UploadPartResult(success: true, sentBytesDelta: lastSent);
    } on dio.DioException catch (e) {
      if (dio.CancelToken.isCancel(e)) {
        if (taskId != null) {
          UploadLogger.logFailure(
            taskId: taskId,
            partType: 'video',
            partIndex: 0,
            error: 'cancelled',
          );
        }
        return const UploadPartResult(success: false, error: 'cancelled');
      }
      final status = e.response?.statusCode;
      final body = e.response?.data;

      // Phase C: Log failure
      if (taskId != null) {
        UploadLogger.logFailure(
          taskId: taskId,
          partType: 'video',
          partIndex: 0,
          error: body?.toString() ?? e.message ?? 'Network error',
          statusCode: status,
        );
      }

      return _errorResult(
        base: 'Video upload error',
        body: body ?? e.message,
        status: status,
        sentBytes: lastSent,
      );
    } catch (e) {
      // Phase C: Log exception
      if (taskId != null) {
        UploadLogger.logFailure(
          taskId: taskId,
          partType: 'video',
          partIndex: 0,
          error: e.toString(),
        );
      }

      return UploadPartResult(
        success: false,
        error: 'Video upload exception: $e',
        sentBytesDelta: lastSent,
      );
    }
  }

  /// Upload single photo bytes for given post UUID.
  /// [taskId] - Task correlation ID for logging and backend tracking.
  /// [aspectRatio], [width], [height] are optional metadata.
  /// [onProgress] receives (sent, total, deltaSent).
  Future<UploadPartResult> uploadPhoto({
    required String postUuid,
    required Uint8List bytes,
    required int index,
    String? taskId,
    double? aspectRatio,
    int? width,
    int? height,
    void Function(int sent, int total, int delta)? onProgress,
  }) async {
    return _withTokenRefresh(
      () => _uploadPhotoInternal(
        postUuid,
        bytes,
        index,
        taskId,
        aspectRatio,
        width,
        height,
        onProgress,
      ),
      onAuthFailed: (error) => UploadPartResult(success: false, error: error),
    );
  }

  Future<UploadPartResult> _uploadPhotoInternal(
    String postUuid,
    Uint8List bytes,
    int index,
    String? taskId,
    double? aspectRatio,
    int? width,
    int? height,
    void Function(int sent, int total, int delta)? onProgress,
  ) async {
    final sizeBytes = bytes.length;
    final startTime = DateTime.now();

    // Phase C: Log upload start
    if (taskId != null) {
      UploadLogger.logPartStart(
        taskId: taskId,
        partType: 'photo',
        partIndex: index,
        postUuid: postUuid,
        sizeBytes: sizeBytes,
      );
    }

    final client = _buildClient(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 60),
    );
    _activeCancelToken = dio.CancelToken();
    int lastSent = 0;

    try {
      final formMap = {
        'uuid': postUuid,
        'file': dio.MultipartFile.fromBytes(
          bytes,
          filename:
              'photo_${index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      };
      // Metadata expected under body.metadata.* on backend; send both numeric ratio and label
      // Backend schema: aspectRatio (string label like "16:9"), ratio (numeric like 1.78)
      if (aspectRatio != null) {
        // Send numeric ratio for backend 'ratio' column
        formMap['ratio'] = aspectRatio.toString();
        formMap['metadata[ratio]'] = aspectRatio.toString();

        // Derive and send string label for backend 'aspectRatio' column
        final label = _deriveAspectRatioLabel(aspectRatio);
        formMap['aspectRatio'] = label;
        formMap['metadata[aspectRatio]'] = label;
      }
      if (width != null) {
        formMap['width'] = width.toString();
        formMap['metadata[width]'] = width.toString();
      }
      if (height != null) {
        formMap['height'] = height.toString();
        formMap['metadata[height]'] = height.toString();
      }

      // PHASE 0: Deep diagnostic logging for photo uploads
      if (kDebugMode) {
        debugPrint('[PHASE_0_PHOTO] Endpoint: ${ApiKey.postPhotosKey}');
        debugPrint(
          '[PHASE_0_PHOTO] TaskId: $taskId | PhotoIndex: $index | PostUuid: ${postUuid.substring(0, min(8, postUuid.length))}...',
        );
        debugPrint(
          '[PHASE_0_PHOTO] Size: ${(sizeBytes / 1024).toStringAsFixed(1)} KB | AspectRatio: $aspectRatio | Width: $width | Height: $height',
        );
        debugPrint('[PHASE_0_PHOTO] FormData keys: ${formMap.keys.toList()}');
        final authToken = (_box ??= GetStorage()).read('ACCESS_TOKEN') ?? '';
        debugPrint(
          '[PHASE_0_PHOTO] Auth token prefix: ${authToken.substring(0, min(20, authToken.length))}...',
        );
      }

      // Phase C: Add correlation header
      final options = dio.Options(
        headers: taskId != null ? {'X-Upload-Task': taskId} : null,
      );

      final resp = await client.post(
        ApiKey.postPhotosKey,
        data: dio.FormData.fromMap(formMap),
        options: options,
        cancelToken: _activeCancelToken,
        onSendProgress: (sent, total) {
          if (_activeCancelToken?.isCancelled == true) return;
          final previous = lastSent;
          lastSent = sent;
          final delta = sent - previous;
          if (delta > 0) {
            onProgress?.call(sent, total, delta);
            // Phase C: Log progress
            if (taskId != null) {
              UploadLogger.logPartProgress(
                taskId: taskId,
                partType: 'photo',
                partIndex: index,
                sent: sent,
                total: total,
              );
            }
          }
        },
      );
      final code = resp.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        // Phase C: Log failure
        if (taskId != null) {
          UploadLogger.logFailure(
            taskId: taskId,
            partType: 'photo',
            partIndex: index,
            error: 'Non-2xx status',
            statusCode: code,
          );
        }
        return _errorResult(
          base: 'Photo upload failed',
          body: resp.data,
          status: code,
          sentBytes: lastSent,
        );
      }

      // Phase C: Log completion
      if (taskId != null) {
        final durationMs = DateTime.now().difference(startTime).inMilliseconds;
        UploadLogger.logPartComplete(
          taskId: taskId,
          partType: 'photo',
          partIndex: index,
          sizeBytes: lastSent,
          durationMs: durationMs,
        );
      }

      return UploadPartResult(success: true, sentBytesDelta: lastSent);
    } on dio.DioException catch (e) {
      if (dio.CancelToken.isCancel(e)) {
        if (taskId != null) {
          UploadLogger.logFailure(
            taskId: taskId,
            partType: 'photo',
            partIndex: index,
            error: 'cancelled',
          );
        }
        return const UploadPartResult(success: false, error: 'cancelled');
      }
      final status = e.response?.statusCode;
      final body = e.response?.data;

      // Phase C: Log failure
      if (taskId != null) {
        UploadLogger.logFailure(
          taskId: taskId,
          partType: 'photo',
          partIndex: index,
          error: body?.toString() ?? e.message ?? 'Network error',
          statusCode: status,
        );
      }

      return _errorResult(
        base: 'Photo upload error',
        body: body ?? e.message,
        status: status,
        sentBytes: lastSent,
      );
    } catch (e) {
      // Phase C: Log exception
      if (taskId != null) {
        UploadLogger.logFailure(
          taskId: taskId,
          partType: 'photo',
          partIndex: index,
          error: e.toString(),
        );
      }

      return UploadPartResult(
        success: false,
        error: 'Photo upload exception: $e',
        sentBytesDelta: lastSent,
      );
    }
  }

  /// Delete post on backend (cascade cleanup). Non-fatal if fails.
  Future<void> deletePostCascade(String postUuid) async {
    final token = _tokenProvider != null
        ? _tokenProvider()
        : (_box ??= GetStorage()).read('ACCESS_TOKEN');
    if (token == null) return;
    try {
      final client = dio.Dio(
        dio.BaseOptions(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 15),
        ),
      );
      final resp = await client.delete('${ApiKey.getPostsKey}/$postUuid');
      if (resp.statusCode != null && resp.statusCode! >= 300) {
        if (Get.isLogEnable) {
          // ignore: avoid_print
          print(
            '[UploadService] delete cascade failed status=${resp.statusCode} body=${resp.data}',
          );
        }
      }
    } catch (e) {
      if (Get.isLogEnable) {
        // ignore: avoid_print
        print('[UploadService] delete cascade exception: $e');
      }
    }
  }
}
