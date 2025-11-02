import 'package:get/get.dart';

/// Utility class for parsing complex JSON responses from the API.
/// These helpers handle various nested structures and fallback strategies
/// for brand, model, and photo path extraction.
class JsonParsers {
  JsonParsers._(); // Private constructor to prevent instantiation

  /// Extract brand name from various JSON structures.
  /// Tries multiple fields and nested objects to find the brand name.
  static String extractBrand(Map<String, dynamic> json) {
    // Prefer explicit name fields first
    final candidates = [json['brandName'], json['brand'], json['brandsName']];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    final brands = json['brands'];
    if (brands is Map) {
      final name = brands['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
      // Sometimes API might nest differently
      final b2 = brands['brand'];
      if (b2 is String && b2.trim().isNotEmpty) return b2.trim();
    } else if (brands is String && brands.trim().isNotEmpty) {
      // Avoid returning full map string representation like {uuid:..., name:...}
      if (brands.startsWith('{') && brands.contains('name:')) {
        // Try to extract name via regex
        final match = RegExp(r'name:([^,}]+)').firstMatch(brands);
        if (match != null) return match.group(1)!.trim();
      } else {
        return brands.trim();
      }
    }
    // Fallback to id (will later be resolved to name)
    final id = json['brandsId']?.toString();
    return id ?? '';
  }

  /// Extract model name from various JSON structures.
  /// Similar to extractBrand, handles multiple nested formats.
  static String extractModel(Map<String, dynamic> json) {
    final candidates = [json['modelName'], json['model'], json['modelsName']];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    final models = json['models'];
    if (models is Map) {
      final name = models['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
      final m2 = models['model'];
      if (m2 is String && m2.trim().isNotEmpty) return m2.trim();
    } else if (models is String && models.trim().isNotEmpty) {
      if (models.startsWith('{') && models.contains('name:')) {
        final match = RegExp(r'name:([^,}]+)').firstMatch(models);
        if (match != null) return match.group(1)!.trim();
      } else {
        return models.trim();
      }
    }
    final id = json['modelsId']?.toString();
    return id ?? '';
  }

  /// Extract photo path from complex nested JSON structures.
  /// Handles arrays, nested objects, and various API response formats.
  static String extractPhotoPath(Map<String, dynamic> json) {
    final direct = json['photoPath'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();

    final photo = json['photo'];
    // Case: photo is a List (home feed style)
    if (photo is List && photo.isNotEmpty) {
      for (final item in photo) {
        if (item is Map) {
          // Typical nested variant map under 'path'
          final p = item['path'];
          if (p is Map) {
            final variant = _pickImageVariant(p);
            if (variant != null) return variant;
          }
          for (final key in ['path', 'photoPath', 'originalPath', 'url']) {
            final v = item[key];
            if (v is String && v.trim().isNotEmpty) return v.trim();
          }
        } else if (item is String && item.trim().isNotEmpty) {
          return item.trim();
        }
      }
    }

    if (photo is Map) {
      for (final key in ['path', 'photoPath', 'originalPath', 'url']) {
        final v = photo[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      final nested = photo['path'];
      if (nested is Map) {
        final variant = _pickImageVariant(nested);
        if (variant != null) return variant;
      }
    }

    final photos = json['photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is Map) {
        for (final key in ['path', 'photoPath', 'originalPath', 'url']) {
          final v = first[key];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        final nested = first['path'];
        if (nested is Map) {
          final variant = _pickImageVariant(nested);
          if (variant != null) return variant;
        }
      } else if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }

    // Deep fallback scan
    final deep = _deepFindFirstImagePath(json);
    if (deep != null) return deep;

    if (Get.isLogEnable) {
      // ignore: avoid_print
      print(
        '[JsonParsers][photo] no photo path keys found (deep fallback also empty) keys=${json.keys}',
      );
    }
    return '';
  }

  /// Pick the best image variant from a map of variants (medium, small, original, etc.)
  static String? _pickImageVariant(Map variantMap) {
    const order = ['medium', 'small', 'originalPath', 'original', 'large'];
    for (final k in order) {
      final v = variantMap[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    for (final value in variantMap.values) {
      if (value is Map) {
        final url = value['url'];
        if (url is String && url.trim().isNotEmpty) return url.trim();
      } else if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Recursively search JSON structure for first valid image path
  static String? _deepFindFirstImagePath(dynamic node, {int depth = 0}) {
    if (depth > 5) return null;
    if (node is String) {
      final s = node.trim();
      if (s.isNotEmpty && _looksLikeImagePath(s)) return s;
    } else if (node is Map) {
      for (final entry in node.entries) {
        final found = _deepFindFirstImagePath(entry.value, depth: depth + 1);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final v in node) {
        final found = _deepFindFirstImagePath(v, depth: depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Check if string looks like an image file path
  static bool _looksLikeImagePath(String s) {
    return RegExp(
      r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$',
      caseSensitive: false,
    ).hasMatch(s);
  }
}
