/// Hashing utilities used for form signature / dirty tracking.
/// Currently implements a 64-bit FNV-1a hash over JSON-encoded map data.
/// Extracted from PostController to reduce controller size and improve testability.
import 'dart:convert';

class HashingUtils {
  const HashingUtils._();

  /// Computes a stable 64-bit FNV-1a hash of the JSON encoding of [map].
  /// Falls back to timestamp string if unexpected failure occurs.
  static String computeSignature(Map<String, dynamic> map) {
    try {
      // Canonicalize: sort keys to ensure order-independent hashing
      final entries = map.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final canonical = <String, dynamic>{
        for (final e in entries) e.key: e.value,
      };
      final jsonStr = jsonEncode(canonical);
      int hash = 0xcbf29ce484222325; // FNV offset basis
      const int prime = 0x100000001b3; // FNV prime
      for (final codeUnit in jsonStr.codeUnits) {
        hash ^= codeUnit;
        hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF; // 64-bit overflow
      }
      return hash.toRadixString(16);
    } catch (_) {
      return DateTime.now().microsecondsSinceEpoch.toString();
    }
  }
}
