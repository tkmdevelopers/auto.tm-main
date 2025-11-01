import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

/// Enum representing standard aspect ratios for images
enum ImageAspectRatio {
  landscape16x9('16:9', 1.78),
  landscape4x3('4:3', 1.33),
  square1x1('1:1', 1.0),
  portrait3x4('3:4', 0.75),
  portrait9x16('9:16', 0.56),
  custom('custom', 0.0);

  final String label;
  final double value;
  const ImageAspectRatio(this.label, this.value);

  @override
  String toString() => label;
}

/// Metadata class containing image information including aspect ratio
class ImageMetadata {
  /// Original image bytes (before optimization)
  final Uint8List bytes;

  /// Original dimensions
  final int originalWidth;
  final int originalHeight;

  /// Optimized dimensions (after compression/resize)
  final int optimizedWidth;
  final int optimizedHeight;

  /// Aspect ratio information
  final double ratio;
  final ImageAspectRatio category;
  final String aspectRatioString;

  /// File size information
  final int originalSize;
  final int optimizedSize;

  /// Compression quality used (1-100)
  final int quality;

  /// Image orientation
  final String orientation; // 'landscape', 'portrait', 'square'

  ImageMetadata({
    required this.bytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.optimizedWidth,
    required this.optimizedHeight,
    required this.ratio,
    required this.category,
    required this.aspectRatioString,
    required this.originalSize,
    required this.optimizedSize,
    required this.quality,
    required this.orientation,
  });

  /// Create ImageMetadata by analyzing raw image bytes
  ///
  /// [bytes] - Raw image bytes
  /// [maxDimension] - Maximum width or height (default: 2048px)
  /// [quality] - JPEG compression quality (default: 85)
  static Future<ImageMetadata> fromBytes(
    Uint8List bytes, {
    int maxDimension = 2048,
    int quality = 85,
  }) async {
    try {
      // Decode image to get dimensions
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final originalWidth = image.width;
      final originalHeight = image.height;
      final originalSize = bytes.length;

      // Calculate aspect ratio
      final ratio = calculateRatio(originalWidth, originalHeight);
      final category = categorizeRatio(ratio);
      final orientation = determineOrientation(ratio);

      // Optimize image (resize if needed, compress)
      final optimizedBytes = await _optimizeImage(
        image,
        maxDimension: maxDimension,
        quality: quality,
      );

      // Get optimized dimensions
      final optimizedImage = img.decodeImage(optimizedBytes);
      final optimizedWidth = optimizedImage?.width ?? originalWidth;
      final optimizedHeight = optimizedImage?.height ?? originalHeight;
      final optimizedSize = optimizedBytes.length;

      debugPrint(
        '[ImageMetadata] Created: ${category.label} '
        '($originalWidth×$originalHeight → $optimizedWidth×$optimizedHeight) '
        '${(originalSize / 1024).toStringAsFixed(1)}KB → ${(optimizedSize / 1024).toStringAsFixed(1)}KB',
      );

      return ImageMetadata(
        bytes: optimizedBytes,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        optimizedWidth: optimizedWidth,
        optimizedHeight: optimizedHeight,
        ratio: ratio,
        category: category,
        aspectRatioString: category.label,
        originalSize: originalSize,
        optimizedSize: optimizedSize,
        quality: quality,
        orientation: orientation,
      );
    } catch (e) {
      debugPrint('[ImageMetadata] Error analyzing image: $e');
      // Return default metadata with original bytes
      return _createDefaultMetadata(bytes);
    }
  }

  /// Optimize image: resize if too large, compress
  static Future<Uint8List> _optimizeImage(
    img.Image image, {
    required int maxDimension,
    required int quality,
  }) async {
    img.Image processedImage = image;

    // Resize if dimensions exceed max
    if (image.width > maxDimension || image.height > maxDimension) {
      int newWidth = image.width;
      int newHeight = image.height;

      if (newWidth > newHeight) {
        // Landscape or square - limit width
        newHeight = (maxDimension * newHeight / newWidth).round();
        newWidth = maxDimension;
      } else {
        // Portrait - limit height
        newWidth = (maxDimension * newWidth / newHeight).round();
        newHeight = maxDimension;
      }

      debugPrint(
        '[ImageMetadata] Resizing: ${image.width}×${image.height} → $newWidth×$newHeight',
      );

      processedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic,
      );
    }

    // Encode as JPEG with quality setting
    final compressed = img.encodeJpg(processedImage, quality: quality);

    return Uint8List.fromList(compressed);
  }

  /// Calculate aspect ratio from dimensions
  static double calculateRatio(int width, int height) {
    if (height == 0) return 1.0;
    return width / height;
  }

  /// Categorize ratio into standard aspect ratio category
  static ImageAspectRatio categorizeRatio(double ratio) {
    const tolerance = 0.05;

    for (final category in ImageAspectRatio.values) {
      if (category == ImageAspectRatio.custom) continue;
      if ((ratio - category.value).abs() < tolerance) {
        return category;
      }
    }

    return ImageAspectRatio.custom;
  }

  /// Determine image orientation from ratio
  static String determineOrientation(double ratio) {
    if ((ratio - 1.0).abs() < 0.1) {
      return 'square';
    } else if (ratio > 1.0) {
      return 'landscape';
    } else {
      return 'portrait';
    }
  }

  /// Create default metadata when analysis fails
  static ImageMetadata _createDefaultMetadata(Uint8List bytes) {
    return ImageMetadata(
      bytes: bytes,
      originalWidth: 800,
      originalHeight: 600,
      optimizedWidth: 800,
      optimizedHeight: 600,
      ratio: 1.33,
      category: ImageAspectRatio.landscape4x3,
      aspectRatioString: '4:3',
      originalSize: bytes.length,
      optimizedSize: bytes.length,
      quality: 85,
      orientation: 'landscape',
    );
  }

  /// Get cache dimensions with specified multiplier
  ///
  /// [multiplier] - Quality multiplier (e.g., 6.0 for 6x)
  /// Returns tuple of (cacheWidth, cacheHeight)
  (int, int) getCacheDimensions({double multiplier = 6.0}) {
    return (
      (optimizedWidth * multiplier).toInt(),
      (optimizedHeight * multiplier).toInt(),
    );
  }

  /// Get display dimensions that fit within container while maintaining aspect ratio
  ///
  /// [containerWidth] - Available width
  /// [containerHeight] - Available height
  /// Returns tuple of (displayWidth, displayHeight)
  (double, double) getDisplayDimensions({
    required double containerWidth,
    required double containerHeight,
  }) {
    double displayWidth = containerWidth;
    double displayHeight = displayWidth / ratio;

    // If height exceeds container, scale down
    if (displayHeight > containerHeight) {
      displayHeight = containerHeight;
      displayWidth = displayHeight * ratio;
    }

    return (displayWidth, displayHeight);
  }

  /// Convert to JSON for API transmission
  Map<String, dynamic> toJson() {
    return {
      'b64': base64Encode(bytes),
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'optimizedWidth': optimizedWidth,
      'optimizedHeight': optimizedHeight,
      'width': optimizedWidth, // For backend compatibility
      'height': optimizedHeight, // For backend compatibility
      'ratio': ratio,
      'aspectRatio': aspectRatioString,
      'category': category.name,
      'orientation': orientation,
      'originalSize': originalSize,
      'optimizedSize': optimizedSize,
      'quality': quality,
    };
  }

  /// Convert to simplified JSON for storage (without base64)
  Map<String, dynamic> toStorageJson() {
    return {
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'optimizedWidth': optimizedWidth,
      'optimizedHeight': optimizedHeight,
      'ratio': ratio,
      'aspectRatio': aspectRatioString,
      'category': category.name,
      'orientation': orientation,
      'originalSize': originalSize,
      'optimizedSize': optimizedSize,
      'quality': quality,
    };
  }

  /// Create from storage JSON (needs bytes separately)
  static ImageMetadata fromStorageJson(
    Map<String, dynamic> json,
    Uint8List bytes,
  ) {
    return ImageMetadata(
      bytes: bytes,
      originalWidth: json['originalWidth'] as int,
      originalHeight: json['originalHeight'] as int,
      optimizedWidth: json['optimizedWidth'] as int,
      optimizedHeight: json['optimizedHeight'] as int,
      ratio: (json['ratio'] as num).toDouble(),
      category: ImageAspectRatio.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ImageAspectRatio.landscape4x3,
      ),
      aspectRatioString: json['aspectRatio'] as String,
      originalSize: json['originalSize'] as int,
      optimizedSize: json['optimizedSize'] as int,
      quality: json['quality'] as int,
      orientation: json['orientation'] as String,
    );
  }

  /// Compression ratio achieved
  double get compressionRatio => originalSize / optimizedSize;

  /// Size reduction percentage
  double get sizeReduction =>
      ((originalSize - optimizedSize) / originalSize) * 100;

  /// Check if image was resized
  bool get wasResized =>
      originalWidth != optimizedWidth || originalHeight != optimizedHeight;

  @override
  String toString() {
    return 'ImageMetadata('
        'ratio: $aspectRatioString, '
        'dimensions: $optimizedWidth×$optimizedHeight, '
        'size: ${(optimizedSize / 1024).toStringAsFixed(1)}KB, '
        'compression: ${compressionRatio.toStringAsFixed(2)}x'
        ')';
  }
}
