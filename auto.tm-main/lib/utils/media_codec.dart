import 'dart:convert';
import 'dart:typed_data';

/// Centralized helpers for media base64 encoding/decoding.
/// Allows future optimization (e.g., moving heavy decode to isolates) without touching controller logic.
class MediaCodec {
  const MediaCodec._();

  static String encodeBytes(Uint8List bytes) => base64Encode(bytes);

  static Uint8List? tryDecode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }
}
