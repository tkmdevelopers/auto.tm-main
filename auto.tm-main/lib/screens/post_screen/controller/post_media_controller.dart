import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Dedicated controller for managing photo and video selection, compression,
/// and playback in the post creation flow.
///
/// **Responsibilities:**
/// - Image picking and removal
/// - Video picking with automatic thumbnail generation
/// - Video compression for files > 25 MB
/// - Video player initialization and lifecycle management
/// - Image signature caching for dirty tracking
///
/// **Extracted from PostController to:**
/// - Reduce complexity (PostController was 1390 LOC)
/// - Improve testability of media handling logic
/// - Separate concerns (media vs. form state vs. upload)
class PostMediaController extends GetxController {
  // ═══════════════════════════════════════════════════════════════════════════
  // Image State
  // ═══════════════════════════════════════════════════════════════════════════

  final RxList<Uint8List> selectedImages = <Uint8List>[].obs;
  List<_ImageSig> _imageSigCache = [];

  // ═══════════════════════════════════════════════════════════════════════════
  // Video State
  // ═══════════════════════════════════════════════════════════════════════════

  final Rxn<File> selectedVideo = Rxn<File>();
  final Rxn<Uint8List> videoThumbnail = Rxn<Uint8List>();
  final RxBool isVideoInitialized = false.obs;
  final RxBool isCompressingVideo = false.obs;
  final RxDouble videoCompressionProgress = 0.0.obs;

  final RxInt originalVideoBytes = 0.obs;
  final RxInt compressedVideoBytes = 0.obs;
  final RxBool usedCompressedVideo = false.obs;
  final Rxn<File> compressedVideoFile = Rxn<File>();

  VideoPlayerController? videoPlayerController;
  Subscription? _videoCompressSub;

  static const int _minVideoCompressBytes = 25 * 1024 * 1024; // 25 MB

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  void _cleanup() {
    videoPlayerController?.dispose();
    videoPlayerController = null;
    _cancelVideoCompression();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Image Management
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> pickImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      for (final image in images) {
        final bytes = await image.readAsBytes();
        selectedImages.add(bytes);
      }

      _rebuildImageSigCache();
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      _rebuildImageSigCache();
    }
  }

  void clearImages() {
    selectedImages.clear();
    _imageSigCache = [];
  }

  void _rebuildImageSigCache() {
    _imageSigCache = selectedImages.map((e) => _ImageSig(e)).toList();
  }

  /// Get image signature cache for dirty tracking
  List<_ImageSig> get imageSigCache => _imageSigCache;

  // ═══════════════════════════════════════════════════════════════════════════
  // Video Management
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        final file = File(video.path);
        selectedVideo.value = file;
        originalVideoBytes.value = await file.length();

        await _generateVideoThumbnail(file.path);

        if (_shouldCompressVideo(originalVideoBytes.value)) {
          await _compressVideo(file);
        } else {
          await _initializeVideoPlayer(file);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video: $e');
    }
  }

  void disposeVideo() {
    try {
      videoPlayerController?.dispose();
      videoPlayerController = null;
      selectedVideo.value = null;
      videoThumbnail.value = null;
      isVideoInitialized.value = false;
      usedCompressedVideo.value = false;
      compressedVideoFile.value = null;
      originalVideoBytes.value = 0;
      compressedVideoBytes.value = 0;
      _cancelVideoCompression();
      _deleteCompressedFile();
    } catch (e) {
      debugPrint('Error disposing video: $e');
    }
  }

  void resetVideo() {
    disposeVideo();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Video Compression
  // ═══════════════════════════════════════════════════════════════════════════

  bool _shouldCompressVideo(int sizeBytes) =>
      sizeBytes >= _minVideoCompressBytes;

  Future<void> _generateVideoThumbnail(String path) async {
    try {
      final thumb = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 75,
      );
      if (thumb != null && thumb.isNotEmpty) {
        videoThumbnail.value = thumb;
      }
    } catch (_) {}
  }

  Future<void> _compressVideo(
    File original, {
    bool forceTranscode = false,
  }) async {
    isCompressingVideo.value = true;
    videoCompressionProgress.value = 0;
    usedCompressedVideo.value = false;

    try {
      _videoCompressSub?.unsubscribe.call();
    } catch (_) {
      // Subscription cleanup failed
    }

    _videoCompressSub = VideoCompress.compressProgress$.subscribe((progress) {
      videoCompressionProgress.value = (progress / 100).clamp(0, 1);
    });

    try {
      final result = await VideoCompress.compressVideo(
        original.path,
        quality: forceTranscode
            ? VideoQuality.MediumQuality
            : VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (result != null && result.file != null) {
        compressedVideoFile.value = result.file;
        try {
          compressedVideoBytes.value = await result.file!.length();
        } catch (_) {}
        usedCompressedVideo.value = true;
        await _initializeVideoPlayer(result.file!);
      } else {
        await _initializeVideoPlayer(original);
      }
    } catch (_) {
      await _initializeVideoPlayer(original);
    } finally {
      try {
        _videoCompressSub?.unsubscribe.call();
      } catch (_) {
        // Subscription cleanup failed
      }
      _videoCompressSub = null;
      isCompressingVideo.value = false;
    }
  }

  Future<void> _initializeVideoPlayer(File file) async {
    try {
      videoPlayerController?.dispose();
      videoPlayerController = VideoPlayerController.file(file);
      await videoPlayerController!.initialize();
      videoPlayerController!.setLooping(false);
      videoPlayerController!.pause();
      videoPlayerController!.setVolume(0);
      isVideoInitialized.value = true;
    } catch (_) {
      isVideoInitialized.value = false;
    }
  }

  void _cancelVideoCompression() {
    if (isCompressingVideo.value) {
      VideoCompress.cancelCompression();
    }
    try {
      _videoCompressSub?.unsubscribe.call();
    } catch (_) {
      // Subscription cleanup failed
    }
    _videoCompressSub = null;
    isCompressingVideo.value = false;
  }

  void _deleteCompressedFile() {
    try {
      final f = compressedVideoFile.value;
      if (f != null && f.existsSync()) {
        f.deleteSync();
      }
    } catch (_) {}
    compressedVideoFile.value = null;
    compressedVideoBytes.value = 0;
    usedCompressedVideo.value = false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // State Reset
  // ═══════════════════════════════════════════════════════════════════════════

  void resetAll() {
    clearImages();
    disposeVideo();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Computed Getters
  // ═══════════════════════════════════════════════════════════════════════════

  bool get hasVideo => selectedVideo.value != null;
  bool get hasImages => selectedImages.isNotEmpty;
  bool get hasAnyMedia => hasImages || hasVideo;

  File? get videoFileForUpload =>
      usedCompressedVideo.value && compressedVideoFile.value != null
      ? compressedVideoFile.value
      : selectedVideo.value;
}

/// Image signature for dirty tracking without storing full bytes in comparison.
class _ImageSig {
  final int length;
  final int firstByte;
  final int lastByte;

  _ImageSig(Uint8List bytes)
    : length = bytes.length,
      firstByte = bytes.isNotEmpty ? bytes.first : 0,
      lastByte = bytes.isNotEmpty ? bytes.last : 0;

  @override
  bool operator ==(Object other) =>
      other is _ImageSig &&
      other.length == length &&
      other.firstByte == firstByte &&
      other.lastByte == lastByte;

  @override
  int get hashCode => Object.hash(length, firstByte, lastByte);
}
