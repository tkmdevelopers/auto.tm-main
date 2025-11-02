import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/utils/key.dart';

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

  /// Cancel current active upload request (video or photo)
  void cancelActive([String reason = 'User cancelled']) {
    try {
      _activeCancelToken?.cancel(reason);
    } catch (_) {}
  }

  /// Upload video file for given post UUID.
  /// [onProgress] receives (sent, total, deltaSent).
  Future<UploadPartResult> uploadVideo({
    required String postUuid,
    required File file,
    void Function(int sent, int total, int delta)? onProgress,
  }) async {
    if (!file.existsSync()) {
      return const UploadPartResult(
        success: true,
      ); // treat missing file as noop success
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

    try {
      final resp = await client.post(
        ApiKey.videoUploadKey,
        data: form,
        cancelToken: _activeCancelToken,
        onSendProgress: (sent, total) {
          final previous = lastSent;
          lastSent = sent; // raw progress for video (single part) OK
          final delta = sent - previous;
          if (delta > 0) {
            onProgress?.call(sent, total, delta);
          }
        },
      );
      if (resp.statusCode != null && resp.statusCode! >= 300) {
        return UploadPartResult(
          success: false,
          error: 'Video upload failed',
          sentBytesDelta: lastSent,
        );
      }
      return UploadPartResult(success: true, sentBytesDelta: lastSent);
    } on dio.DioException catch (e) {
      if (dio.CancelToken.isCancel(e)) {
        return UploadPartResult(success: false, error: 'cancelled');
      }
      final status = e.response?.statusCode;
      final body = e.response?.data;
      return UploadPartResult(
        success: false,
        error:
            'Video upload error${status != null ? ' ($status)' : ''}: ${body ?? e.message}',
      );
    } catch (e) {
      return UploadPartResult(
        success: false,
        error: 'Video upload exception: $e',
      );
    }
  }

  /// Upload single photo bytes for given post UUID.
  /// [aspectRatio], [width], [height] are optional metadata.
  /// [onProgress] receives (sent, total, deltaSent).
  Future<UploadPartResult> uploadPhoto({
    required String postUuid,
    required Uint8List bytes,
    required int index,
    double? aspectRatio,
    int? width,
    int? height,
    void Function(int sent, int total, int delta)? onProgress,
  }) async {
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
      if (aspectRatio != null) formMap['aspectRatio'] = aspectRatio;
      if (width != null) formMap['width'] = width.toString();
      if (height != null) formMap['height'] = height.toString();

      await client.post(
        ApiKey.postPhotosKey,
        data: dio.FormData.fromMap(formMap),
        cancelToken: _activeCancelToken,
        onSendProgress: (sent, total) {
          final previous = lastSent;
          // use similar concept but simpler (photo part independent)
          lastSent = sent;
          final delta = sent - previous;
          if (delta > 0) {
            onProgress?.call(sent, total, delta);
          }
        },
      );
      return UploadPartResult(success: true, sentBytesDelta: lastSent);
    } on dio.DioException catch (e) {
      if (dio.CancelToken.isCancel(e)) {
        return const UploadPartResult(success: false, error: 'cancelled');
      }
      final status = e.response?.statusCode;
      final body = e.response?.data;
      return UploadPartResult(
        success: false,
        error:
            'Photo upload error${status != null ? ' ($status)' : ''}: ${body ?? e.message}',
      );
    } catch (e) {
      return UploadPartResult(
        success: false,
        error: 'Photo upload exception: $e',
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
