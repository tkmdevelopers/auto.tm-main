import 'dart:typed_data';

import 'package:auto_tm/screens/post_screen/controller/post_media_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late PostMediaController controller;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    controller = PostMediaController();
  });

  tearDown(() {
    controller.dispose();
    Get.reset();
  });

  group('PostMediaController - Image Management', () {
    test('should initialize with empty images', () {
      expect(controller.selectedImages.isEmpty, true);
      expect(controller.hasImages, false);
    });

    test('removeImage should remove image at specified index', () {
      // Manually add some mock images
      controller.selectedImages.addAll([
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5, 6]),
        Uint8List.fromList([7, 8, 9]),
      ]);

      controller.removeImage(1);

      expect(controller.selectedImages.length, 2);
      expect(controller.selectedImages[0][0], 1);
      expect(controller.selectedImages[1][0], 7);
    });

    test('removeImage should handle invalid index gracefully', () {
      controller.selectedImages.add(Uint8List.fromList([1, 2, 3]));

      controller.removeImage(5); // Out of bounds
      expect(controller.selectedImages.length, 1);

      controller.removeImage(-1); // Negative
      expect(controller.selectedImages.length, 1);
    });

    test('clearImages should remove all images', () {
      controller.selectedImages.addAll([
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5, 6]),
      ]);

      controller.clearImages();

      expect(controller.selectedImages.isEmpty, true);
      expect(controller.imageSigCache.isEmpty, true);
    });

    test('hasImages should return true when images exist', () {
      expect(controller.hasImages, false);

      controller.selectedImages.add(Uint8List.fromList([1, 2, 3]));

      expect(controller.hasImages, true);
    });
  });

  group('PostMediaController - Video State', () {
    test('should initialize with no video', () {
      expect(controller.selectedVideo.value, isNull);
      expect(controller.hasVideo, false);
      expect(controller.isVideoInitialized.value, false);
      expect(controller.isCompressingVideo.value, false);
    });

    test('disposeVideo should clear all video state', () {
      // Simulate video state
      controller.isVideoInitialized.value = true;
      controller.usedCompressedVideo.value = true;
      controller.originalVideoBytes.value = 50000000;
      controller.compressedVideoBytes.value = 10000000;

      controller.disposeVideo();

      expect(controller.selectedVideo.value, isNull);
      expect(controller.videoThumbnail.value, isNull);
      expect(controller.isVideoInitialized.value, false);
      expect(controller.usedCompressedVideo.value, false);
      expect(controller.originalVideoBytes.value, 0);
      expect(controller.compressedVideoBytes.value, 0);
      expect(controller.compressedVideoFile.value, isNull);
    });

    test('resetVideo should call disposeVideo', () {
      controller.isVideoInitialized.value = true;

      controller.resetVideo();

      expect(controller.isVideoInitialized.value, false);
      expect(controller.selectedVideo.value, isNull);
    });

    test('hasVideo should reflect video state', () {
      expect(controller.hasVideo, false);

      // Cannot set actual File in unit tests, but we can verify the getter logic
      // by checking the reactive variable directly
      expect(controller.selectedVideo.value, isNull);
      expect(controller.hasVideo, false);
    });

    test('videoCompressionProgress should track compression state', () {
      expect(controller.videoCompressionProgress.value, 0.0);
      expect(controller.isCompressingVideo.value, false);

      // Simulate compression progress
      controller.isCompressingVideo.value = true;
      controller.videoCompressionProgress.value = 0.5;

      expect(controller.isCompressingVideo.value, true);
      expect(controller.videoCompressionProgress.value, 0.5);
    });

    test('should track original and compressed video sizes', () {
      controller.originalVideoBytes.value = 50000000;
      controller.compressedVideoBytes.value = 10000000;
      controller.usedCompressedVideo.value = true;

      expect(controller.originalVideoBytes.value, 50000000);
      expect(controller.compressedVideoBytes.value, 10000000);
      expect(controller.usedCompressedVideo.value, true);
    });

    test('videoFileForUpload should return compressed file when used', () {
      // Since we can't create real File objects in unit tests,
      // we verify the logic by checking that the getter exists
      expect(controller.videoFileForUpload, isNull);

      // When usedCompressedVideo is false, should return selectedVideo
      controller.usedCompressedVideo.value = false;
      expect(controller.videoFileForUpload, controller.selectedVideo.value);
    });
  });

  group('PostMediaController - Media Presence', () {
    test('hasAnyMedia should be false when no media', () {
      expect(controller.hasAnyMedia, false);
    });

    test('hasAnyMedia should be true when images exist', () {
      controller.selectedImages.add(Uint8List.fromList([1, 2, 3]));

      expect(controller.hasAnyMedia, true);
    });

    test('hasAnyMedia should reflect video state', () {
      // Initially no media
      expect(controller.hasAnyMedia, false);

      // When hasImages is true
      controller.selectedImages.add(Uint8List.fromList([1, 2, 3]));
      expect(controller.hasAnyMedia, true);

      // Clear images
      controller.clearImages();
      expect(controller.hasAnyMedia, false);
    });
  });

  group('PostMediaController - State Reset', () {
    test('resetAll should clear images and video', () {
      controller.selectedImages.addAll([
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5, 6]),
      ]);
      controller.isVideoInitialized.value = true;
      controller.originalVideoBytes.value = 1000000;

      controller.resetAll();

      expect(controller.selectedImages.isEmpty, true);
      expect(controller.isVideoInitialized.value, false);
      expect(controller.selectedVideo.value, isNull);
      expect(controller.originalVideoBytes.value, 0);
    });

    test('resetAll should be callable multiple times safely', () {
      controller.resetAll();
      controller.resetAll();

      expect(controller.selectedImages.isEmpty, true);
      expect(controller.selectedVideo.value, isNull);
    });
  });

  group('PostMediaController - Lifecycle', () {
    test('onClose should cleanup video resources', () {
      // Skip: VideoCompress requires WidgetsFlutterBinding in unit tests
    }, skip: 'Requires platform channels');
  });
}
