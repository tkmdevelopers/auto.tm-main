// ignore_for_file: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';

/// Optimized cached network image with automatic memory management
/// Now with adaptive aspect ratio support for optimal display
class CachedImageHelper {
  /// Maximum cache size in MB (default 100MB)
  static const int maxCacheSizeMB = 100;

  /// Maximum cache age in days (default 30 days)
  static const int maxCacheDays = 30;

  /// Build a cached network image with optimized settings
  static Widget buildCachedImage({
    required String imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    int? cacheWidth,
    int? cacheHeight,
    Duration fadeInDuration = const Duration(milliseconds: 300),
  }) {
    // Debug logging
    if (imageUrl.isEmpty) {
      debugPrint('[CachedImageHelper] ❌ ERROR: Empty image URL provided');
      return _buildErrorWidget(width, height);
    }

    debugPrint(
      '[CachedImageHelper] 🖼️ Loading image: ${imageUrl.length > 100 ? imageUrl.substring(0, 100) + "..." : imageUrl}',
    );

    // Use CachedNetworkImage for better performance
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: fadeInDuration,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheHeight,
      placeholder: placeholder != null
          ? (context, url) {
              debugPrint(
                '[CachedImageHelper] ⏳ Placeholder shown for: ${url.length > 50 ? url.substring(0, 50) + "..." : url}',
              );
              return placeholder;
            }
          : (context, url) {
              debugPrint(
                '[CachedImageHelper] ⏳ Default placeholder for: ${url.length > 50 ? url.substring(0, 50) + "..." : url}',
              );
              return _buildShimmer(width, height);
            },
      errorWidget: errorWidget != null
          ? (context, url, error) {
              debugPrint(
                '[CachedImageHelper] ❌ Custom error widget for: $url\n   Error: $error',
              );
              return errorWidget;
            }
          : (context, url, error) {
              debugPrint(
                '[CachedImageHelper] ❌ Error loading: $url\n   Error type: ${error.runtimeType}\n   Error: $error',
              );
              // Attempt lightweight HEAD validation & single retry for transient network/content-type issues
              return _RetryImage(
                originalUrl: url,
                width: width,
                height: height,
                fit: fit,
              );
            },
      imageBuilder: (context, imageProvider) {
        debugPrint('[CachedImageHelper] ✅ Successfully loaded image');
        return Image(
          image: imageProvider,
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }

  /// Build a cached network image for thumbnails (optimized for small sizes)
  static Widget buildThumbnail({
    required String imageUrl,
    double size = 80,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    return buildCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      placeholder: placeholder,
      // 4x for sharper thumbnails on high-DPI displays
      cacheWidth: (size * 4).toInt(),
      cacheHeight: (size * 4).toInt(),
    );
  }

  /// Build a cached network image for list items (optimized for scrolling)
  static Widget buildListItemImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    bool highQuality = false,
  }) {
    // For high quality, use 6x multiplier, otherwise 5x (ultra-sharp for modern displays)
    final multiplier = highQuality ? 6 : 5;

    return buildCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Optimized for high-DPI displays (5x-6x)
      cacheWidth: (width * multiplier).toInt(),
      cacheHeight: (height * multiplier).toInt(),
    );
  }

  /// Build a cached network image for full-screen display
  static Widget buildFullScreenImage({
    required String imageUrl,
    BoxFit fit = BoxFit.contain,
  }) {
    return buildCachedImage(
      imageUrl: imageUrl,
      fit: fit,
      // Don't limit cache size for full-screen images
      fadeInDuration: const Duration(milliseconds: 500),
    );
  }

  /// Build a cached circular avatar
  static Widget buildCachedAvatar({
    required String imageUrl,
    required double radius,
    Widget? placeholder,
  }) {
    return ClipOval(
      child: buildCachedImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: placeholder,
        cacheWidth: (radius * 8)
            .toInt(), // 4x multiplier for ultra-sharp avatars
        cacheHeight: (radius * 8).toInt(),
      ),
    );
  }

  /// Build image for post with proper validation and fallback
  /// This ensures posts without images show a proper placeholder
  /// [isThumbnail] - set to true for small thumbnails to use lower multiplier (4x instead of 6x)
  static Widget buildPostImage({
    required String? photoPath,
    required String baseUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    String? fallbackUrl,
    bool isThumbnail = false,
  }) {
    // Validate and construct URL
    String imageUrl;

    if (photoPath == null || photoPath.trim().isEmpty) {
      // No photo path - use fallback or default
      imageUrl =
          fallbackUrl ??
          'https://placehold.co/${width.toInt()}x${height.toInt()}/e0e0e0/666666?text=No+Image';
      debugPrint(
        '[CachedImageHelper] 📷 No photo path provided, using fallback',
      );
    } else {
      // 🔧 FIX: Normalize backslashes to forward slashes (Windows paths)
      final normalizedPath = photoPath.replaceAll('\\', '/');

      if (normalizedPath.startsWith('http')) {
        imageUrl = normalizedPath;
      } else {
        // Ensure proper URL construction without double slashes
        final cleanBaseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
        final cleanPath = normalizedPath.startsWith('/')
            ? normalizedPath
            : '/$normalizedPath';

        imageUrl = '$cleanBaseUrl$cleanPath';
      }

      debugPrint('[CachedImageHelper] 🔧 Original: $photoPath');
      debugPrint('[CachedImageHelper] 🔧 Normalized: $normalizedPath');
      debugPrint(
        '[CachedImageHelper] 🌐 Final URL: ${imageUrl.length > 80 ? imageUrl.substring(0, 80) + '...' : imageUrl}',
      );
    }

    // Choose multiplier based on usage:
    // - Thumbnails (small): 4x (e.g., 120×120 → 480×480) - balanced quality
    // - Full posts (large): 6x (e.g., 600×200 → 3600×1200) - ultra-sharp
    final multiplier = isThumbnail ? 4 : 6;

    return buildCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (width * multiplier).toInt(),
      cacheHeight: (height * multiplier).toInt(),
    );
  }

  /// Default shimmer placeholder
  static Widget _buildShimmer(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.grey[600],
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Default error widget with better visibility
  static Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[200]!, Colors.grey[300]!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            color: Colors.grey[500],
            size: width != null ? (width * 0.4).clamp(32, 64) : 48,
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build adaptive post image using aspect ratio metadata
  /// Automatically calculates optimal dimensions based on photo metadata
  /// Includes aspect ratio in cache key for consistency
  static Widget buildAdaptivePostImage({
    required Photo photo,
    required String baseUrl,
    required double containerWidth,
    required double containerHeight,
    BoxFit fit = BoxFit.cover,
    bool isThumbnail = false,
  }) {
    // Get the best available photo path
    final photoPath = photo.bestPath;

    if (photoPath.isEmpty) {
      debugPrint('[CachedImageHelper] 📷 No photo path in Photo object');
      return _buildErrorWidget(containerWidth, containerHeight);
    }

    // Calculate optimal dimensions based on aspect ratio metadata
    final dimensions = _calculateOptimalDimensions(
      photo: photo,
      containerWidth: containerWidth,
      containerHeight: containerHeight,
    );

    // Construct URL with aspect ratio consideration
    final imageUrl = _constructImageUrl(photoPath, baseUrl);

    debugPrint(
      '[CachedImageHelper] 🎯 Adaptive image: ${photo.aspectRatio ?? 'unknown'} '
      '(${photo.width}x${photo.height}) → ${dimensions.width.toInt()}x${dimensions.height.toInt()}',
    );

    // Choose multiplier based on usage
    final multiplier = isThumbnail ? 4 : 6;

    return buildCachedImage(
      imageUrl: imageUrl,
      width: containerWidth,
      height: containerHeight,
      fit: fit,
      cacheWidth: (dimensions.width * multiplier).toInt(),
      cacheHeight: (dimensions.height * multiplier).toInt(),
    );
  }

  /// Calculate optimal dimensions for display based on aspect ratio metadata
  /// Returns dimensions that fit within container while maintaining aspect ratio
  static ({double width, double height}) _calculateOptimalDimensions({
    required Photo photo,
    required double containerWidth,
    required double containerHeight,
  }) {
    // If we have ratio metadata, use it for precise calculation
    if (photo.ratio != null && photo.ratio! > 0) {
      final ratio = photo.ratio!;

      // Calculate dimensions that fit in container while maintaining ratio
      double width = containerWidth;
      double height = width / ratio;

      if (height > containerHeight) {
        // Height exceeds container, scale down
        height = containerHeight;
        width = height * ratio;
      }

      return (width: width, height: height);
    }

    // If we have width/height, calculate ratio
    if (photo.width != null &&
        photo.height != null &&
        photo.width! > 0 &&
        photo.height! > 0) {
      final ratio = photo.width! / photo.height!;

      double width = containerWidth;
      double height = width / ratio;

      if (height > containerHeight) {
        height = containerHeight;
        width = height * ratio;
      }

      return (width: width, height: height);
    }

    // Fallback: use standard aspect ratios based on orientation
    if (photo.orientation != null) {
      switch (photo.orientation) {
        case 'landscape':
          return _fitToRatio(containerWidth, containerHeight, 16 / 9);
        case 'portrait':
          return _fitToRatio(containerWidth, containerHeight, 9 / 16);
        case 'square':
          return _fitToRatio(containerWidth, containerHeight, 1.0);
      }
    }

    // Ultimate fallback: assume 4:3 (common default)
    return _fitToRatio(containerWidth, containerHeight, 4 / 3);
  }

  /// Helper to fit dimensions to a specific ratio within container
  static ({double width, double height}) _fitToRatio(
    double containerWidth,
    double containerHeight,
    double ratio,
  ) {
    double width = containerWidth;
    double height = width / ratio;

    if (height > containerHeight) {
      height = containerHeight;
      width = height * ratio;
    }

    return (width: width, height: height);
  }

  /// Construct proper image URL from path and base URL
  static String _constructImageUrl(String photoPath, String baseUrl) {
    final normalizedPath = photoPath.replaceAll('\\', '/');

    if (normalizedPath.startsWith('http')) {
      return normalizedPath;
    }

    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = normalizedPath.startsWith('/')
        ? normalizedPath
        : '/$normalizedPath';

    return '$cleanBaseUrl$cleanPath';
  }

  /// Get recommended cache dimensions based on aspect ratio category
  /// Optimizes memory usage by using standard sizes for each ratio
  static ({int width, int height}) getRecommendedCacheDimensions({
    String? aspectRatio,
    double quality = 1.0, // 0.5 = half, 1.0 = standard, 1.5 = high
  }) {
    final multiplier = quality;

    switch (aspectRatio) {
      case '16:9': // Wide landscape (videos, modern monitors)
        return (
          width: (1920 * multiplier).toInt(),
          height: (1080 * multiplier).toInt(),
        );
      case '4:3': // Standard landscape (traditional photos)
        return (
          width: (1600 * multiplier).toInt(),
          height: (1200 * multiplier).toInt(),
        );
      case '1:1': // Square (Instagram-style)
        return (
          width: (1080 * multiplier).toInt(),
          height: (1080 * multiplier).toInt(),
        );
      case '9:16': // Tall portrait (stories, reels)
        return (
          width: (1080 * multiplier).toInt(),
          height: (1920 * multiplier).toInt(),
        );
      case '3:4': // Portrait (traditional photos)
        return (
          width: (1200 * multiplier).toInt(),
          height: (1600 * multiplier).toInt(),
        );
      default: // Unknown or custom - use balanced 4:3
        return (
          width: (1600 * multiplier).toInt(),
          height: (1200 * multiplier).toInt(),
        );
    }
  }

  /// Clear specific image from cache
  static Future<void> clearImageCache(String imageUrl) async {
    await CachedNetworkImage.evictFromCache(imageUrl);
  }

  /// Clear all cached images (warning: expensive operation)
  /// Only use this when user explicitly requests cache clearing or on logout
  static Future<void> clearAllCache() async {
    try {
      // Use DefaultCacheManager from flutter_cache_manager package
      // cached_network_image uses this as its default cache manager
      final DefaultCacheManager cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();
      debugPrint(
        '[CachedImageHelper] 🗑️ All image cache cleared successfully',
      );
    } catch (e) {
      debugPrint('[CachedImageHelper] ❌ Error clearing cache: $e');
    }
  }
}

/// Internal widget that performs a single delayed retry after validating
/// that the remote resource looks like an image (basic Content-Type check).
class _RetryImage extends StatefulWidget {
  final String originalUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _RetryImage({
    required this.originalUrl,
    required this.width,
    required this.height,
    required this.fit,
  });

  @override
  State<_RetryImage> createState() => _RetryImageState();
}

class _RetryImageState extends State<_RetryImage> {
  bool _attempted = false;
  bool _validImage = true;

  @override
  void initState() {
    super.initState();
    _validateAndRetry();
  }

  Future<void> _validateAndRetry() async {
    if (_attempted) return; // safety
    _attempted = true;
    try {
      final uri = Uri.tryParse(widget.originalUrl);
      if (uri == null) {
        _validImage = false;
        return;
      }
      // Perform a HEAD request to verify content type if http/https
      if (uri.scheme.startsWith('http')) {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 3);
        try {
          final req = await client.openUrl('HEAD', uri);
          final resp = await req.close();
          final ctype = resp.headers.value('content-type') ?? '';
          debugPrint(
            '[CachedImageHelper] 🔍 HEAD status=${resp.statusCode} type=$ctype url=${widget.originalUrl}',
          );
          if (resp.statusCode >= 400 ||
              !(ctype.contains('image/') ||
                  ctype.contains('jpeg') ||
                  ctype.contains('png'))) {
            _validImage = false;
            return;
          }
        } catch (e) {
          debugPrint('[CachedImageHelper] ⚠️ HEAD check failed: $e');
        } finally {
          client.close(force: true);
        }
      }
      // Delay then trigger rebuild to attempt CachedNetworkImage again externally (parent won't auto retry itself)
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(
        () {},
      ); // triggers one rebuild; parent CachedNetworkImage already failed so we simulate retry via Image.network
    } catch (_) {
      _validImage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_attempted) {
      return CachedImageHelper._buildShimmer(widget.width, widget.height);
    }
    if (!_validImage) {
      return CachedImageHelper._buildErrorWidget(widget.width, widget.height);
    }
    // Simple direct Image.network fallback (can leverage cache manager again)
    return Image.network(
      widget.originalUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (_, __, ___) =>
          CachedImageHelper._buildErrorWidget(widget.width, widget.height),
    );
  }
}
