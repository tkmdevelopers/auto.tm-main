import 'package:auto_tm/utils/cached_image_helper.dart';

/// Service for managing application caches
///
/// This service provides cache management capabilities including:
/// - Image cache clearing
/// - Cache size monitoring (future implementation)
/// - Automatic cache cleanup on app start
class CacheManagementService {
  static final CacheManagementService _instance =
      CacheManagementService._internal();
  factory CacheManagementService() => _instance;
  CacheManagementService._internal();

  /// Clear all image caches
  /// Note: This is an expensive operation and should only be called
  /// when user explicitly requests it (e.g., in settings)
  Future<void> clearImageCaches() async {
    await CachedImageHelper.clearAllCache();
  }

  /// Clear specific image from cache
  Future<void> clearSpecificImage(String imageUrl) async {
    await CachedImageHelper.clearImageCache(imageUrl);
  }

  /// Initialize cache management on app start
  /// Currently, cached_network_image handles automatic cache management
  /// based on its default settings (max 200 cached files, 30 days stalePeriod)
  Future<void> initialize() async {
    // Future: Add custom cache cleanup logic here if needed
    // For now, rely on cached_network_image's built-in cache management
  }

  /// Get cache information for display in settings
  /// Returns a map with cache statistics
  Future<Map<String, dynamic>> getCacheInfo() async {
    return {
      'maxCacheObjects': 200, // default from cached_network_image
      'stalePeriodDays': 30, // default from cached_network_image
      'note': 'Cache is automatically managed',
    };
  }
}
