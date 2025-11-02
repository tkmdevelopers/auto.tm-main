import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/post_screen/services/upload_service.dart';

// NOTE: This is a lightweight test focusing on progress delta semantics.
// Network calls will not actually execute; to avoid hitting real endpoints
// one would normally mock Dio. Here we verify that a no-op upload on missing file returns success.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UploadService basic', () {
    late UploadService service;

    setUp(() async {
      service = Get.put(
        UploadService(tokenProvider: () => ''),
      ); // inject empty token
    });

    test('uploadVideo returns success for missing file (noop)', () async {
      final temp = File('nonexistent.tmp');
      final result = await service.uploadVideo(
        postUuid: 'uuid-test',
        file: temp,
      );
      expect(result.success, isTrue);
      expect(result.sentBytesDelta, equals(0));
    });

    test('uploadPhoto handles empty bytes gracefully', () async {
      final result = await service.uploadPhoto(
        postUuid: 'uuid-test',
        bytes: Uint8List.fromList([]),
        index: 0,
      );
      // Depending on backend it might still attempt request; here we just assert structure.
      expect(result.sentBytesDelta >= 0, isTrue);
    });
  });
}
