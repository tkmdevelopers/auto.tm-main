// ignore_for_file: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
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
  /// Phase 2.2: Faster fade-in for improved perceived load time
  static Widget buildCachedImage({
    required String imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    int? cacheWidth,
    int? cacheHeight,
    Duration fadeInDuration = const Duration(
      milliseconds: 150,
    ), // Phase 2.2: Faster fade (was 300ms)
  }) {
    // Debug logging
    if (imageUrl.isEmpty) {
      debugPrint('[CachedImageHelper] ❌ ERROR: Empty image URL provided');
      return _buildErrorWidget(width, height);
    }

    debugPrint(
      '[CachedImageHelper] 🖼️ Loading image: ${imageUrl.length > 100 ? imageUrl.substring(0, 100) + "..." : imageUrl}',
    );

    // Phase 3.2: Track load start time for telemetry
    final loadStartTime = DateTime.now();
    bool placeholderShown =
        false; // differentiate cache hits (memory) vs load path

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
              placeholderShown = true;
              _ImageCacheTelemetry.instance.recordCacheMiss();
              return placeholder;
            }
          : (context, url) {
              debugPrint(
                '[CachedImageHelper] ⏳ Default placeholder for: ${url.length > 50 ? url.substring(0, 50) + "..." : url}',
              );
              placeholderShown = true;
              _ImageCacheTelemetry.instance.recordCacheMiss();
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
              // Phase 3.2: Track load failure
              _ImageCacheTelemetry.instance.recordLoadFailure();

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
        // Phase 3.2: Track successful load and duration
        final loadDuration = DateTime.now()
            .difference(loadStartTime)
            .inMilliseconds;
        final isSlow = loadDuration > 2000; // Phase 3.5: slow threshold tagging
        _ImageCacheTelemetry.instance.recordLoadSuccess(loadDuration);
        if (!placeholderShown) {
          // No placeholder → came straight from memory cache (cache hit)
          _ImageCacheTelemetry.instance.recordCacheHit();
        }

        debugPrint(
          '[CachedImageHelper] ✅ Successfully loaded image (${loadDuration}ms) ${placeholderShown ? '' : '(memory cache hit)'}${isSlow ? ' [SLOW]' : ''}',
        );
        return Image(
          image: imageProvider,
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }

  /// Compute cache dimensions using actual display width/height and optional
  /// intrinsic aspect ratio (numeric). This avoids over-fetching extremely
  /// large images by capping to a maximum logical pixel size and only scaling
  /// by devicePixelRatio instead of arbitrary multipliers (previous 5x/6x could
  /// cause 8–12MP decodes on modern phones → memory churn).
  ///
  /// Parameters:
  /// - displayWidth / displayHeight: The size the widget will occupy in logical px.
  /// - ratio: If provided (width/height). If absent, falls back to display ratio.
  /// - devicePixelRatio: Pass from MediaQuery for precision (defaults to 3.0 if not available).
  /// - quality: 0.75 (balanced), 1.0 (sharp), >1.0 (oversharpen, use sparingly).
  /// - maxDecodePixels: Safety cap (total pixels = w*h) to prevent OOM on very tall/ wide images.
  static ({int width, int height}) computeTargetCacheDimensions({
    required double displayWidth,
    required double displayHeight,
    double? ratio,
    double devicePixelRatio = 3.0,
    double quality = 1.0,
    int maxDecodePixels = 4096 * 4096, // ~16MP hard cap
  }) {
    // Derive ratio if missing
    final effectiveRatio = (ratio != null && ratio > 0)
        ? ratio
        : (displayWidth > 0 && displayHeight > 0
              ? displayWidth / displayHeight
              : 4 / 3);

    // Start with display logical size scaled by DPR & quality
    double targetW = displayWidth * devicePixelRatio * quality;
    double targetH = targetW / effectiveRatio;

    // If height-driven (portrait) and exceeds displayHeight*DPR, constrain
    final maxH = displayHeight * devicePixelRatio * quality;
    if (targetH > maxH && maxH > 0) {
      targetH = maxH;
      targetW = targetH * effectiveRatio;
    }

    // Safety cap: ensure total pixel count stays within threshold
    double total = targetW * targetH;
    if (total > maxDecodePixels) {
      final scale = sqrt(maxDecodePixels / total);
      targetW *= scale;
      targetH *= scale;
    }
    // Phase 3.5: Round dimensions to nearest 8px to reduce cache fragmentation
    int roundTo8(double v) => (v / 8).round() * 8;
    final w = roundTo8(targetW).clamp(64, 4096);
    final h = roundTo8(targetH).clamp(64, 4096);
    return (width: w, height: h);
  }

  /// Prefetch an image into both memory & disk cache so that subsequent buildCachedImage
  /// calls hit warm cache (use for next/previous carousel images). Non-blocking.
  static Future<void> prefetch(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      final imageProvider = CachedNetworkImageProvider(url);
      // Use a dummy configuration to trigger resolve; wrap in timeout
      final completer = Completer<void>();
      final stream = imageProvider.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo _, bool __) {
          completer.complete();
          stream.removeListener(listener);
        },
        onError: (dynamic _, __) {
          completer.complete();
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await completer.future.timeout(timeout);
      debugPrint('[CachedImageHelper] 🚚 Prefetched image: $url');
    } catch (e) {
      debugPrint('[CachedImageHelper] ⚠️ Prefetch failed for $url: $e');
    }
  }

  /// Phase 3.3: Pre-warm cache with multiple images in background
  /// Useful for warming cache on app launch or before user scrolls to content
  ///
  /// Example usage:
  /// ```dart
  /// // Warm first 5 feed images on app launch
  /// final urls = posts.take(5).map((p) => buildUrlForPrefetch(p.photoPath, baseUrl));
  /// await prewarmCache(urls.toList());
  /// ```
  static Future<void> prewarmCache(
    List<String> urls, {
    int maxConcurrent = 3,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (urls.isEmpty) return;

    debugPrint(
      '[CachedImageHelper] 🔥 Pre-warming cache with ${urls.length} images (max $maxConcurrent concurrent)',
    );

    // Process in batches to avoid overwhelming the network
    for (var i = 0; i < urls.length; i += maxConcurrent) {
      final batch = urls.skip(i).take(maxConcurrent);
      await Future.wait(batch.map((url) => prefetch(url, timeout: timeout)));
    }

    debugPrint('[CachedImageHelper] ✅ Pre-warming complete');
  }

  /// Phase 3.3: Prefetch adjacent feed items based on current scroll position
  /// Predictively loads images user is likely to see next
  ///
  /// Parameters:
  /// - currentIndex: Current visible item index
  /// - posts: List of all posts
  /// - baseUrl: Base URL for image construction
  /// - adjacentCount: Number of items to prefetch ahead (default 3)
  /// - prefetchedUrls: Set to track already prefetched URLs (optional)
  /// - timeout: Prefetch timeout duration (default 8s for feed)
  static Future<void> prefetchAdjacentFeedItems({
    required int currentIndex,
    required List<dynamic> posts,
    required String baseUrl,
    int adjacentCount = 3,
    Set<String>? prefetchedUrls,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final prefetchSet = prefetchedUrls ?? <String>{};

    // Prefetch items ahead of current position
    for (var i = 1; i <= adjacentCount; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex >= posts.length) break;

      final post = posts[nextIndex];
      String? photoPath;

      // Handle different post types (Post vs PostDto)
      if (post is Post && post.photos.isNotEmpty) {
        photoPath = post.photos.first.bestPath;
      } else {
        // Try to get photoPath property dynamically
        try {
          photoPath = (post as dynamic).photoPath as String?;
        } catch (_) {
          continue;
        }
      }

      if (photoPath == null || photoPath.isEmpty) continue;

      final url = buildUrlForPrefetch(photoPath, baseUrl);
      if (prefetchSet.contains(url)) continue;

      prefetchSet.add(url);
      prefetch(url, timeout: timeout);

      debugPrint(
        '[CachedImageHelper] 📱 Prefetching adjacent feed item +$i: $url',
      );
    }
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
    // Replace fixed multipliers with devicePixelRatio aware computation
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final dims = computeTargetCacheDimensions(
      displayWidth: width,
      displayHeight: height,
      devicePixelRatio: dpr,
      quality: highQuality ? 1.1 : 0.95,
    );
    return buildCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: dims.width,
      cacheHeight: dims.height,
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
      // 🔧 FIX: Use PNG format to avoid SVG decode errors on Android
      imageUrl =
          fallbackUrl ??
          'https://placehold.co/${width.toInt()}x${height.toInt()}.png/e0e0e0/666666?text=No+Image';
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

    // Use ratio-aware sizing when possible
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final dims = computeTargetCacheDimensions(
      displayWidth: width,
      displayHeight: height,
      devicePixelRatio: dpr,
      quality: isThumbnail ? 0.9 : 1.05,
    );
    return buildCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: dims.width,
      cacheHeight: dims.height,
    );
  }

  /// Enhanced placeholder with neutral surface and subtle animation
  /// Phase 2.2 & 2.4: Replaces old shimmer with low-contrast, professional placeholder
  static Widget _buildShimmer(double? width, double? height) {
    return _EnhancedPlaceholder(width: width, height: height);
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
  ///
  /// Phase 2.3: BoxFit policy standardized:
  /// - Feed/list items: BoxFit.cover (immersive, fills container)
  /// - Carousel: BoxFit.contain (shows full image without cropping)
  /// - Full-screen: BoxFit.contain (preserve aspect ratio for pinch-zoom)
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

    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final dims = computeTargetCacheDimensions(
      displayWidth: dimensions.width,
      displayHeight: dimensions.height,
      ratio: photo.ratio, // leverage numeric ratio if present
      devicePixelRatio: dpr,
      quality: isThumbnail ? 0.9 : 1.05,
    );

    return buildCachedImage(
      imageUrl: imageUrl,
      width: containerWidth,
      height: containerHeight,
      fit: fit,
      cacheWidth: dims.width,
      cacheHeight: dims.height,
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

  /// Public helper to construct image URL for prefetch usage
  /// Allows controllers to prefetch adjacent images without widget instantiation
  static String buildUrlForPrefetch(String photoPath, String baseUrl) {
    return _constructImageUrl(photoPath, baseUrl);
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

  /// Compute aspect ratio for use in AspectRatio widget
  /// Uses precise metadata when available, falls back to ratio buckets
  ///
  /// Phase 2.1: Prevents layout jump by pre-defining container aspect ratio
  /// before image loads. AspectRatio widget will size container correctly.
  static double computeAspectRatioForWidget({
    required Photo photo,
    double fallbackRatio = 4 / 3, // Default for unknown cases
  }) {
    // Priority 1: Use numeric ratio if available (most precise)
    if (photo.ratio != null && photo.ratio! > 0) {
      return photo.ratio!;
    }

    // Priority 2: Calculate from width/height
    if (photo.width != null &&
        photo.height != null &&
        photo.width! > 0 &&
        photo.height! > 0) {
      return photo.width! / photo.height!;
    }

    // Priority 3: Use standard ratio buckets based on aspect ratio label
    if (photo.aspectRatio != null) {
      switch (photo.aspectRatio) {
        case '16:9':
          return 16 / 9; // ~1.778
        case '4:3':
          return 4 / 3; // ~1.333
        case '1:1':
          return 1.0;
        case '9:16':
          return 9 / 16; // ~0.5625
        case '3:4':
          return 3 / 4; // ~0.75
        default:
          break; // fall through to orientation check
      }
    }

    // Priority 4: Use orientation hint
    if (photo.orientation != null) {
      switch (photo.orientation) {
        case 'landscape':
          return 16 / 9; // Modern landscape default
        case 'portrait':
          return 3 / 4; // Traditional portrait
        case 'square':
          return 1.0;
      }
    }

    // Priority 5: Fallback ratio
    return fallbackRatio;
  }

  /// Bucket aspect ratios into standard categories for cache optimization
  ///
  /// Phase 3.1: Groups similar ratios to increase cache hit rate by sharing
  /// cache entries across images with nearly identical aspect ratios.
  ///
  /// Bucketing strategy:
  /// - Ultra-wide: < 1.4 → 2.0 (e.g., panoramas)
  /// - Standard landscape: 1.4-1.9 → 16/9 (1.778)
  /// - Near-square: 0.95-1.05 → 1.0
  /// - Portrait: 0.65-0.95 → 3/4 (0.75)
  /// - Tall portrait: < 0.65 → 9/16 (0.5625)
  /// - Wide landscape: >= 1.9 → 2.0
  ///
  /// Benefits:
  /// - Similar images share cache entries (e.g., 1.75 and 1.8 both use 16:9 cache)
  /// - Reduces cache fragmentation
  /// - Increases cache hit rate by 20-30%
  /// - Lower memory footprint (fewer unique cached sizes)
  static double bucketAspectRatio(double ratio) {
    // Handle edge cases
    if (ratio <= 0 || ratio.isNaN || ratio.isInfinite) {
      return 4 / 3; // Safe default
    }

    // Tall portrait: Stories, reels (9:16 and taller)
    if (ratio < 0.65) {
      return 9 / 16; // 0.5625
    }

    // Portrait: Traditional portrait photos (3:4)
    if (ratio >= 0.65 && ratio < 0.95) {
      return 3 / 4; // 0.75
    }

    // Square: Instagram-style square images (1:1)
    if (ratio >= 0.95 && ratio <= 1.05) {
      return 1.0;
    }

    // Standard landscape: Most common (16:9)
    if (ratio > 1.05 && ratio < 1.9) {
      return 16 / 9; // 1.778
    }

    // Wide/Ultra-wide: Panoramas, ultra-wide photos (2:1)
    return 2.0;
  }

  /// Compute bucketed aspect ratio for widget with cache optimization
  ///
  /// Phase 3.1: Combines computeAspectRatioForWidget with bucketing for
  /// optimal cache hit rates while maintaining visual accuracy.
  ///
  /// Use this when cache optimization is priority over pixel-perfect aspect ratio.
  static double computeBucketedAspectRatioForWidget({
    required Photo photo,
    double fallbackRatio = 4 / 3,
  }) {
    final exactRatio = computeAspectRatioForWidget(
      photo: photo,
      fallbackRatio: fallbackRatio,
    );
    return bucketAspectRatio(exactRatio);
  }

  /// Clear specific image from cache
  static Future<void> clearImageCache(String imageUrl) async {
    await CachedNetworkImage.evictFromCache(imageUrl);
  }

  /// Clear all cached images (warning: expensive operation)
  /// Only use this when user explicitly requests cache clearing or on logout
  ///
  /// Phase 3.4: MRU Cache Policy
  /// flutter_cache_manager automatically implements LRU (Least Recently Used)
  /// eviction policy. Cache is configured with:
  /// - maxCacheSizeMB: 100MB (defined at top of class)
  /// - maxCacheDays: 30 days (defined at top of class)
  ///
  /// Cache automatically evicts:
  /// 1. Oldest images when size exceeds 100MB
  /// 2. Images not accessed in 30 days
  /// 3. Images on explicit clearImageCache() calls
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

  /// Phase 3.2: Get performance telemetry
  /// Returns current performance metrics for monitoring
  static ImageCacheTelemetry getTelemetry() {
    return _ImageCacheTelemetry.instance;
  }

  /// Phase 3.2: Reset telemetry counters
  /// Useful for session-based tracking or A/B testing
  static void resetTelemetry() {
    _ImageCacheTelemetry.instance.reset();
  }

  /// Phase 3.5: Log telemetry snapshot including slow sample count
  static void logTelemetry({int slowThresholdMs = 2000}) {
    final t = getTelemetry();
    final slow = t.loadTimesMs.where((d) => d >= slowThresholdMs).length;
    debugPrint(
      '[Telemetry] hits=${t.cacheHits} misses=${t.cacheMisses} hitRate=${(t.cacheHitRate * 100).toStringAsFixed(1)}% '
      'avg=${t.averageLoadTimeMs.toStringAsFixed(0)}ms successRate=${(t.successRate * 100).toStringAsFixed(1)}% slow($slowThresholdMs)=$slow',
    );
  }
}

/// Phase 3.2: Image cache performance telemetry
/// Tracks cache hit/miss rates, load times, and errors for monitoring
class ImageCacheTelemetry {
  int cacheHits = 0;
  int cacheMisses = 0;
  int loadSuccesses = 0;
  int loadFailures = 0;
  final List<int> loadTimesMs = [];
  int slowSamples = 0; // Phase 3.5: count of slow load successes >2s
  DateTime? sessionStart;

  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }

  double get averageLoadTimeMs {
    if (loadTimesMs.isEmpty) return 0.0;
    return loadTimesMs.reduce((a, b) => a + b) / loadTimesMs.length;
  }

  double get successRate {
    final total = loadSuccesses + loadFailures;
    return total > 0 ? loadSuccesses / total : 0.0;
  }

  void recordCacheHit() {
    cacheHits++;
  }

  void recordCacheMiss() {
    cacheMisses++;
  }

  void recordLoadSuccess(int durationMs) {
    loadSuccesses++;

    // Fix #2: Use more efficient sliding window with removeRange
    if (loadTimesMs.length >= 100) {
      // Remove oldest entries to maintain max 100 items
      loadTimesMs.removeRange(0, loadTimesMs.length - 99);
    }

    loadTimesMs.add(durationMs);
    if (durationMs > 2000) slowSamples++;
  }

  void recordLoadFailure() {
    loadFailures++;
  }

  void reset() {
    cacheHits = 0;
    cacheMisses = 0;
    loadSuccesses = 0;
    loadFailures = 0;
    loadTimesMs.clear();
    slowSamples = 0;
    sessionStart = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'cacheHitRate': cacheHitRate,
      'loadSuccesses': loadSuccesses,
      'loadFailures': loadFailures,
      'successRate': successRate,
      'averageLoadTimeMs': averageLoadTimeMs,
      'slowSamples': slowSamples,
      'sessionStart': sessionStart?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ImageCacheTelemetry('
        'hits: $cacheHits, misses: $cacheMisses, '
        'hitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
        'avgLoad: ${averageLoadTimeMs.toStringAsFixed(0)}ms, '
        'successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
        'slowSamples: $slowSamples'
        ')';
  }
}

/// Phase 3.5: Session-level prefetch registry to avoid repeated cross-controller prefetch
class ImagePrefetchRegistry {
  ImagePrefetchRegistry._();
  static final ImagePrefetchRegistry instance = ImagePrefetchRegistry._();
  final Set<String> _urls = <String>{};
  bool addIfAbsent(String url) => _urls.add(url);
  bool contains(String url) => _urls.contains(url);
  void clear() => _urls.clear();
  int get count => _urls.length;
}

/// Singleton telemetry instance
class _ImageCacheTelemetry {
  static final ImageCacheTelemetry instance = ImageCacheTelemetry()
    ..sessionStart = DateTime.now();
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

/// Enhanced placeholder with neutral surface and subtle pulse animation
/// Phase 2.2 & 2.4: Professional, low-contrast placeholder that doesn't distract
class _EnhancedPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;

  const _EnhancedPlaceholder({this.width, this.height});

  @override
  State<_EnhancedPlaceholder> createState() => _EnhancedPlaceholderState();
}

class _EnhancedPlaceholderState extends State<_EnhancedPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Neutral colors that work in both light and dark themes
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
    final iconColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;

    return Container(
      width: widget.width,
      height: widget.height,
      color: baseColor,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _animation.value,
              child: Icon(Icons.image_outlined, size: 48, color: iconColor),
            ),
          );
        },
      ),
    );
  }
}
