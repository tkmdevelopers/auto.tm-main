import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_tm/screens/post_screen/controller/upload_manager.dart';
import 'package:auto_tm/models/image_metadata.dart';

void main() {
  group('Lazy Encoding Snapshot', () {
    test('getPhotoBytes returns raw bytes when useLazyEncoding=true', () async {
      final raw = List.generate(
        5,
        (i) => Uint8List.fromList(List<int>.filled(4 + i, i + 1)),
      );
      final meta = raw
          .map(
            (b) => ImageMetadata(
              bytes: b,
              originalWidth: 10,
              originalHeight: 10,
              optimizedWidth: 10,
              optimizedHeight: 10,
              ratio: 1.0,
              category: ImageAspectRatio.square1x1,
              aspectRatioString: ImageAspectRatio.square1x1.label,
              originalSize: b.lengthInBytes,
              optimizedSize: b.lengthInBytes,
              quality: 100,
              orientation: 'up',
            ),
          )
          .toList();

      final snap = PostUploadSnapshot(
        brandUuid: null,
        modelUuid: null,
        brandName: 'TestBrand',
        modelName: 'TestModel',
        photoBytesLengths: raw.map((b) => b.lengthInBytes).toList(),
        photoBase64: const [], // empty upfront
        photoAspectRatios: const ['1:1', '1:1', '1:1', '1:1', '1:1'],
        photoWidths: const [10, 10, 10, 10, 10],
        photoHeights: const [10, 10, 10, 10, 10],
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '100',
        description: 'desc',
        draftId: '',
        rawPhotoMetadata: meta,
        useLazyEncoding: true,
      );

      for (var i = 0; i < meta.length; i++) {
        final bytes = await snap.getPhotoBytes(i);
        expect(
          bytes,
          isNotNull,
          reason: 'Bytes should not be null for index $i',
        );
        expect(
          bytes,
          equals(meta[i].bytes),
          reason: 'Should return raw bytes for index $i',
        );
      }
    });

    test('getPhotoBytes decodes base64 when useLazyEncoding=false', () async {
      // Use existing encoding path by constructing with photoBase64
      final bytes = Uint8List.fromList([1, 2, 3]);
      final b64 = base64Encode(bytes);

      final snap = PostUploadSnapshot(
        brandUuid: null,
        modelUuid: null,
        brandName: 'Brand',
        modelName: 'Model',
        photoBytesLengths: [bytes.length],
        photoBase64: [b64],
        photoAspectRatios: const ['1:1'],
        photoWidths: const [10],
        photoHeights: const [10],
        hasVideo: false,
        videoFile: null,
        usedCompressedVideo: false,
        compressedVideoFile: null,
        originalVideoBytes: 0,
        compressedVideoBytes: 0,
        price: '55',
        description: 'd',
        draftId: '',
        rawPhotoMetadata: null,
        useLazyEncoding: false,
      );

      final out = await snap.getPhotoBytes(0);
      expect(out, isNotNull);
      expect(out, equals(bytes));
    });
  });
}
