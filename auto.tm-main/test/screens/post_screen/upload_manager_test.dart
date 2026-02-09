import 'package:auto_tm/screens/post_screen/controller/upload_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('PostUploadSnapshot - Serialization', () {
    test('should serialize and deserialize snapshot correctly', () {
      final original = PostUploadSnapshot(
        brandUuid: 'brand-uuid-123',
        modelUuid: 'model-uuid-456',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [1024, 2048, 3072],
        photoBase64: ['base64photo1', 'base64photo2'],
        hasVideo: true,
        videoFile: null,
        usedCompressedVideo: true,
        compressedVideoFile: null,
        originalVideoBytes: 50000000,
        compressedVideoBytes: 10000000,
        price: '25000',
        description: 'Well maintained car',
        draftId: 'draft-123',
      );

      final map = original.toMap();
      final restored = PostUploadSnapshot.fromMap(map);

      expect(restored.brandUuid, original.brandUuid);
      expect(restored.modelUuid, original.modelUuid);
      expect(restored.brandName, original.brandName);
      expect(restored.modelName, original.modelName);
      expect(restored.photoBytesLengths, original.photoBytesLengths);
      expect(restored.photoBase64, original.photoBase64);
      expect(restored.hasVideo, original.hasVideo);
      expect(restored.usedCompressedVideo, original.usedCompressedVideo);
      expect(restored.originalVideoBytes, original.originalVideoBytes);
      expect(restored.compressedVideoBytes, original.compressedVideoBytes);
      expect(restored.price, original.price);
      expect(restored.description, original.description);
      expect(restored.draftId, original.draftId);
    });

    test('should handle null and empty values in snapshot', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: null,
        modelUuid: null,
        brandName: '',
        modelName: '',
        photoBytesLengths: [],
        photoBase64: [],
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '',
        description: '',
        draftId: '',
      );

      final map = snapshot.toMap();
      final restored = PostUploadSnapshot.fromMap(map);

      expect(restored.brandUuid, isNull);
      expect(restored.modelUuid, isNull);
      expect(restored.brandName, '');
      expect(restored.photoBytesLengths, isEmpty);
      expect(restored.photoBase64, isEmpty);
      expect(restored.hasVideo, false);
      expect(restored.draftId, '');
    });

    test('should preserve photo base64 data for crash recovery', () {
      final photoData = List.generate(3, (i) => 'base64_photo_$i');

      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [1024, 2048, 3072],
        photoBase64: photoData,
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '15000',
        description: 'Good condition',
        draftId: '',
      );

      final map = snapshot.toMap();
      final restored = PostUploadSnapshot.fromMap(map);

      expect(restored.photoBase64.length, 3);
      expect(restored.photoBase64[0], 'base64_photo_0');
      expect(restored.photoBase64[1], 'base64_photo_1');
      expect(restored.photoBase64[2], 'base64_photo_2');
    });

    test('should handle missing fields during deserialization', () {
      final map = <String, dynamic>{
        'brandName': 'Toyota',
        'modelName': 'Camry',
      };

      final snapshot = PostUploadSnapshot.fromMap(map);

      expect(snapshot.brandUuid, isNull);
      expect(snapshot.modelUuid, isNull);
      expect(snapshot.brandName, 'Toyota');
      expect(snapshot.modelName, 'Camry');
      expect(snapshot.photoBytesLengths, isEmpty);
      expect(snapshot.photoBase64, isEmpty);
      expect(snapshot.hasVideo, false);
      expect(snapshot.price, '');
      expect(snapshot.description, '');
    });
  });

  group('UploadTask - State Management', () {
    test('should initialize with preparing phase', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [],
        photoBase64: [],
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '10000',
        description: 'Test',
        draftId: '',
      );

      final task = UploadTask(id: 'task-1', snapshot: snapshot);

      expect(task.phase.value, UploadPhase.preparing);
      expect(task.overallProgress.value, 0.0);
      expect(task.isCompleted.value, false);
      expect(task.isFailed.value, false);
      expect(task.isCancelled.value, false);
      expect(task.status.value, 'Preparing upload...');
      expect(task.speedDisplay.value, '—');
      expect(task.etaDisplay.value, '--:--');
    });

    test('should track upload phases correctly', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [],
        photoBase64: [],
        hasVideo: true,
        videoFile: null,
        usedCompressedVideo: true,
        compressedVideoFile: null,
        originalVideoBytes: 50000000,
        compressedVideoBytes: 10000000,
        price: '20000',
        description: 'Test upload',
        draftId: '',
      );

      final task = UploadTask(id: 'task-2', snapshot: snapshot);

      // Simulate phase progression
      task.phase.value = UploadPhase.uploadingVideo;
      expect(task.phase.value, UploadPhase.uploadingVideo);

      task.phase.value = UploadPhase.uploadingPhotos;
      expect(task.phase.value, UploadPhase.uploadingPhotos);

      task.phase.value = UploadPhase.finalizing;
      expect(task.phase.value, UploadPhase.finalizing);

      task.phase.value = UploadPhase.complete;
      expect(task.phase.value, UploadPhase.complete);
    });

    test('should track progress for video and photos separately', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [1024, 2048, 3072],
        photoBase64: ['p1', 'p2', 'p3'],
        hasVideo: true,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 10000000,
        compressedVideoBytes: 0,
        price: '15000',
        description: 'Progress test',
        draftId: '',
      );

      final task = UploadTask(id: 'task-3', snapshot: snapshot);

      task.videoProgress.value = 0.5;
      task.photosProgress.value = 0.75;

      expect(task.videoProgress.value, 0.5);
      expect(task.photosProgress.value, 0.75);
    });

    test('should handle failure state with error message', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [],
        photoBase64: [],
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '5000',
        description: 'Failure test',
        draftId: '',
      );

      final task = UploadTask(id: 'task-4', snapshot: snapshot);

      task.phase.value = UploadPhase.failed;
      task.isFailed.value = true;
      task.error.value = 'Network connection lost';
      task.failureType.value = UploadFailureType.network;

      expect(task.phase.value, UploadPhase.failed);
      expect(task.isFailed.value, true);
      expect(task.error.value, 'Network connection lost');
      expect(task.failureType.value, UploadFailureType.network);
    });

    test('should handle cancellation state', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [],
        photoBase64: [],
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '8000',
        description: 'Cancel test',
        draftId: '',
      );

      final task = UploadTask(id: 'task-5', snapshot: snapshot);

      task.phase.value = UploadPhase.cancelled;
      task.isCancelled.value = true;
      task.failureType.value = UploadFailureType.cancelled;

      expect(task.phase.value, UploadPhase.cancelled);
      expect(task.isCancelled.value, true);
      expect(task.failureType.value, UploadFailureType.cancelled);
    });

    test('should store published post ID on completion', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [],
        photoBase64: [],
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '12000',
        description: 'Success test',
        draftId: '',
      );

      final task = UploadTask(id: 'task-6', snapshot: snapshot);

      task.phase.value = UploadPhase.complete;
      task.isCompleted.value = true;
      task.publishedPostId.value = 'published-post-uuid-789';

      expect(task.isCompleted.value, true);
      expect(task.publishedPostId.value, 'published-post-uuid-789');
    });

    test('should track media size metadata', () {
      final snapshot = PostUploadSnapshot(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Toyota',
        modelName: 'Camry',
        photoBytesLengths: [1024, 2048, 3072],
        photoBase64: ['p1', 'p2', 'p3'],
        hasVideo: true,
        videoFile: null,
        usedCompressedVideo: true,
        compressedVideoFile: null,
        originalVideoBytes: 50000000,
        compressedVideoBytes: 10000000,
        price: '30000',
        description: 'Size test',
        draftId: '',
      );

      final task = UploadTask(id: 'task-7', snapshot: snapshot);

      task.videoBytes = 10000000;
      task.photosBytes = 6144; // Sum of photo sizes

      expect(task.videoBytes, 10000000);
      expect(task.photosBytes, 6144);
      expect(task.snapshot.originalVideoBytes, 50000000);
      expect(task.snapshot.compressedVideoBytes, 10000000);
    });
  });

  group('UploadPhase - Enum Values', () {
    test('should have all required upload phases', () {
      expect(UploadPhase.values, contains(UploadPhase.preparing));
      expect(UploadPhase.values, contains(UploadPhase.uploadingVideo));
      expect(UploadPhase.values, contains(UploadPhase.uploadingPhotos));
      expect(UploadPhase.values, contains(UploadPhase.finalizing));
      expect(UploadPhase.values, contains(UploadPhase.complete));
      expect(UploadPhase.values, contains(UploadPhase.failed));
      expect(UploadPhase.values, contains(UploadPhase.cancelled));
    });

    test('should have exactly 7 upload phases', () {
      expect(UploadPhase.values.length, 7);
    });
  });

  group('UploadFailureType - Enum Values', () {
    test('should have all failure types', () {
      expect(UploadFailureType.values, contains(UploadFailureType.network));
      expect(UploadFailureType.values, contains(UploadFailureType.validation));
      expect(UploadFailureType.values, contains(UploadFailureType.cancelled));
      expect(UploadFailureType.values, contains(UploadFailureType.unknown));
    });

    test('should have exactly 4 failure types', () {
      expect(UploadFailureType.values.length, 4);
    });
  });
}
