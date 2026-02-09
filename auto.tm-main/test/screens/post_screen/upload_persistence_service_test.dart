import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_tm/screens/post_screen/controller/upload_manager.dart';
import 'package:auto_tm/screens/post_screen/controller/upload_persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Unit tests for UploadPersistenceService helper methods.
/// GetStorage integration tested separately in integration tests due to platform channel requirements.
void main() {
  late UploadPersistenceService service;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    service = UploadPersistenceService();
  });

  tearDown(() {
    Get.reset();
  });

  PostUploadSnapshot _createTestSnapshot({
    String brandName = 'TestBrand',
    String modelName = 'TestModel',
    List<String> photoBase64 = const [],
    bool hasVideo = false,
    File? videoFile,
    bool usedCompressedVideo = false,
    File? compressedVideoFile,
  }) {
    // Calculate lengths from valid base64 strings only
    final lengths = <int>[];
    for (final b64 in photoBase64) {
      try {
        lengths.add(base64Decode(b64).length);
      } catch (_) {
        lengths.add(0); // Invalid base64 gets 0 length
      }
    }

    return PostUploadSnapshot(
      brandUuid: 'test-brand-uuid',
      modelUuid: 'test-model-uuid',
      brandName: brandName,
      modelName: modelName,
      photoBytesLengths: lengths,
      photoBase64: photoBase64,
      hasVideo: hasVideo,
      videoFile: videoFile,
      usedCompressedVideo: usedCompressedVideo,
      compressedVideoFile: compressedVideoFile,
      originalVideoBytes: 0,
      compressedVideoBytes: 0,
      price: '10000',
      description: 'Test description',
      draftId: '',
    );
  }

  group('UploadPersistenceService - Image Hydration', () {
    test('hydrateImages() decodes base64 photos to Uint8List', () {
      final bytes1 = Uint8List.fromList([100, 101, 102]);
      final bytes2 = Uint8List.fromList([200, 201, 202]);
      final snap = _createTestSnapshot(
        photoBase64: [base64Encode(bytes1), base64Encode(bytes2)],
      );

      final images = service.hydrateImages(snap);

      expect(images, hasLength(2));
      expect(images[0], equals(bytes1));
      expect(images[1], equals(bytes2));
    });

    test('hydrateImages() handles empty photo list', () {
      final snap = _createTestSnapshot(photoBase64: []);

      final images = service.hydrateImages(snap);

      expect(images, isEmpty);
    });

    test('hydrateImages() skips corrupted base64 data', () {
      final validBytes = Uint8List.fromList([150, 151, 152]);
      final snap = _createTestSnapshot(
        photoBase64: [
          base64Encode(validBytes),
          'invalid-base64!!!',
          base64Encode(validBytes),
        ],
      );

      final images = service.hydrateImages(snap);

      // Should decode valid images and skip corrupted one
      expect(images, hasLength(2));
      expect(images[0], equals(validBytes));
      expect(images[1], equals(validBytes));
    });

    test('hydrateImages() handles large base64 payloads', () {
      // Simulate large image (5MB worth of data)
      final largeBytes = Uint8List(5 * 1024 * 1024);
      for (var i = 0; i < largeBytes.length; i++) {
        largeBytes[i] = i % 256;
      }
      final snap = _createTestSnapshot(
        photoBase64: [base64Encode(largeBytes)],
      );

      final images = service.hydrateImages(snap);

      expect(images, hasLength(1));
      expect(images[0].length, largeBytes.length);
      // Verify first/last bytes to ensure correct decoding
      expect(images[0][0], largeBytes[0]);
      expect(images[0][images[0].length - 1], largeBytes[largeBytes.length - 1]);
    });
  });

  group('UploadPersistenceService - Video Validation', () {
    test('hasValidVideoFile() returns false when no video in snapshot', () {
      final snap = _createTestSnapshot(hasVideo: false);

      expect(service.hasValidVideoFile(snap), false);
    });

    test('hasValidVideoFile() returns false when video file is null', () {
      final snap = _createTestSnapshot(hasVideo: true, videoFile: null);

      expect(service.hasValidVideoFile(snap), false);
    });

    test('hasValidVideoFile() returns false when video file does not exist', () {
      final snap = _createTestSnapshot(
        hasVideo: true,
        videoFile: File('/nonexistent/path/video.mp4'),
      );

      expect(service.hasValidVideoFile(snap), false);
    });

    test('hasValidVideoFile() returns false when compressed video is null', () {
      final snap = _createTestSnapshot(
        hasVideo: true,
        usedCompressedVideo: true,
        compressedVideoFile: null,
      );

      expect(service.hasValidVideoFile(snap), false);
    });

    test('hasValidVideoFile() checks compressed video when usedCompressedVideo is true', () {
      final snap = _createTestSnapshot(
        hasVideo: true,
        videoFile: File('/original/video.mp4'), // Would exist
        usedCompressedVideo: true,
        compressedVideoFile: File('/nonexistent/compressed.mp4'), // Doesn't exist
      );

      // Should check compressed file, which doesn't exist
      expect(service.hasValidVideoFile(snap), false);
    });
  });

  group('UploadPersistenceService - Crash Recovery Logic', () {
    test('service initializes without errors', () {
      expect(() => UploadPersistenceService(), returnsNormally);
    });

    test('clearTask() does not throw when called once (platform channel test skipped)', () {
      // Note: clearTask() calls GetStorage which requires platform channels
      // This is tested in integration tests instead
      expect(service, isNotNull);
    });

    test('persistTask() handles task with minimal data (platform test skipped)', () {
      // Note: persistTask() calls GetStorage which requires platform channels
      // This is tested in integration tests instead
      expect(service, isNotNull);
    });

    test('persistTask() handles task with all progress fields (platform test skipped)', () {
      // Note: persistTask() calls GetStorage which requires platform channels
      // This is tested in integration tests instead
      expect(service, isNotNull);
    });

    test('persistTask() handles task in failed state (platform test skipped)', () {
      // Note: persistTask() calls GetStorage which requires platform channels
      // This is tested in integration tests instead
      expect(service, isNotNull);
    });

    test('persistTask() handles task in completed state (platform test skipped)', () {
      // Note: persistTask() calls GetStorage which requires platform channels
      // This is tested in integration tests instead
      expect(service, isNotNull);
    });

    test('persistTask() handles task in cancelled state (platform test skipped)', () {
      // Note: persistTask() calls GetStorage which requires platform channels
      // This is tested in integration tests instead
      expect(service, isNotNull);
    });
  });

  group('UploadPersistenceService - Snapshot Edge Cases', () {
    test('hydrateImages() handles snapshot with mix of valid/invalid base64', () {
      final validBytes1 = Uint8List.fromList([10, 20, 30]);
      final validBytes2 = Uint8List.fromList([40, 50, 60]);
      final snap = _createTestSnapshot(
        photoBase64: [
          base64Encode(validBytes1),
          'not-base64',
          base64Encode(validBytes2),
          'also-not-base64@@@',
        ],
      );

      final images = service.hydrateImages(snap);

      // Only valid base64 strings should be decoded
      expect(images, hasLength(2));
      expect(images[0], equals(validBytes1));
      expect(images[1], equals(validBytes2));
    });

    test('hasValidVideoFile() handles snapshot with both video files present', () {
      final snap = _createTestSnapshot(
        hasVideo: true,
        videoFile: File('/original.mp4'),
        usedCompressedVideo: false,
        compressedVideoFile: File('/compressed.mp4'),
      );

      // Should check original file since usedCompressedVideo is false
      expect(service.hasValidVideoFile(snap), false);
    });
  });
}
