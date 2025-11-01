// ignore_for_file: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Optimized cached network image with automatic memory management
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
              return _buildErrorWidget(width, height);
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
