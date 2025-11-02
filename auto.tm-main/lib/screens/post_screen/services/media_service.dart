import 'dart:typed_data';
import 'dart:io';
import 'package:auto_tm/models/image_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoValidationResult {
  final bool isValid;
  final int? durationSeconds;
  final String? errorMessage;

  const VideoValidationResult({
    required this.isValid,
    this.durationSeconds,
    this.errorMessage,
  });
}

class VideoProcessResult {
  final File originalFile;
  final File playbackFile;
  final File? compressedFile;
  final bool usedCompressed;
  final Uint8List? thumbnailBytes;
  final int originalBytes;
  final int? compressedBytes;

  const VideoProcessResult({
    required this.originalFile,
    required this.playbackFile,
    required this.compressedFile,
    required this.usedCompressed,
    required this.thumbnailBytes,
    required this.originalBytes,
    required this.compressedBytes,
  });
}

class MediaService {
  static const int defaultCompressThresholdBytes = 25 * 1024 * 1024; // 25 MB

  final ImagePicker _picker = ImagePicker();

  /// Picks multiple images and analyzes metadata.
  Future<List<ImageMetadata>> pickAndAnalyzeImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    final List<ImageMetadata> result = [];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final metadata = await ImageMetadata.fromBytes(bytes);
      result.add(metadata);
    }
    return result;
  }

  /// Picks a single video file from the gallery.
  Future<File?> pickVideoFile() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    return video != null ? File(video.path) : null;
  }

  bool shouldCompressVideo(int sizeBytes, {int? thresholdBytes}) {
    final threshold = thresholdBytes ?? defaultCompressThresholdBytes;
    return sizeBytes >= threshold;
  }

  Future<VideoValidationResult> validateVideoDuration(
    File videoFile, {
    required int maxDurationSeconds,
  }) async {
    try {
      final tempController = VideoPlayerController.file(videoFile);
      await tempController.initialize();
      final durationSeconds = tempController.value.duration.inSeconds;
      await tempController.dispose();

      if (durationSeconds > maxDurationSeconds) {
        return VideoValidationResult(
          isValid: false,
          durationSeconds: durationSeconds,
          errorMessage:
              'Maximum video length is $maxDurationSeconds seconds. Your video is $durationSeconds seconds.',
        );
      }

      return VideoValidationResult(
        isValid: true,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugPrint('Error validating video duration: $e');
      return const VideoValidationResult(isValid: true);
    }
  }

  Future<Uint8List?> generateVideoThumbnail(File video) async {
    try {
      final thumb = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 75,
      );
      return thumb;
    } catch (_) {
      return null;
    }
  }

  Future<VideoProcessResult> processVideo({
    required File video,
    required bool shouldCompress,
    int? thresholdBytes,
    void Function(double progress)? onProgress,
  }) async {
    Uint8List? thumb;
    File? compressed;
    int? compressedBytes;
    final int originalBytes = await video.length();
    dynamic subscription;

    try {
      // Generate thumbnail first - fail fast if this fails
      thumb = await generateVideoThumbnail(video);

      if (shouldCompress) {
        // Set up progress subscription before compression starts
        if (onProgress != null) {
          try {
            subscription = VideoCompress.compressProgress$.subscribe((
              progress,
            ) {
              onProgress((progress / 100).clamp(0, 1));
            });
          } catch (e) {
            debugPrint('Failed to subscribe to compression progress: $e');
          }
        }

        try {
          final result = await VideoCompress.compressVideo(
            video.path,
            quality: VideoQuality.MediumQuality,
            deleteOrigin: false,
            includeAudio: true,
          );

          if (result != null && result.file != null) {
            compressed = result.file;
            try {
              compressedBytes = await result.file!.length();
            } catch (e) {
              debugPrint('Failed to get compressed file size: $e');
            }
          }
        } catch (e) {
          debugPrint('Video compression failed: $e');
          // Don't throw - return original video instead
        }
      }
    } catch (e) {
      debugPrint('Video processing error: $e');
      // If thumbnail generation fails, continue without thumbnail
    } finally {
      // Always clean up subscription
      if (subscription != null) {
        try {
          subscription.unsubscribe?.call();
        } catch (_) {
          try {
            subscription.cancel();
          } catch (_) {}
        }
      }
    }

    return VideoProcessResult(
      originalFile: video,
      playbackFile: compressed ?? video,
      compressedFile: compressed,
      usedCompressed: compressed != null,
      thumbnailBytes: thumb,
      originalBytes: originalBytes,
      compressedBytes: compressedBytes,
    );
  }

  Future<void> cancelCompression() async {
    try {
      await VideoCompress.cancelCompression();
    } catch (_) {}
  }

  Future<void> disposeCompressionCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }
}
