import 'package:get_storage/get_storage.dart';
import '../model/brand_dto.dart';
import '../model/model_dto.dart';

/// Service for managing local cache of brands and models with TTL-based expiration.
///
/// Responsibilities:
/// - Persist and retrieve brand/model lists with timestamps
/// - Check cache freshness based on TTL
/// - Support per-brand model caching
/// - Provide memory cache for frequently accessed models
class CacheService {
  final GetStorage _storage;

  static const _brandCacheKey = 'BRAND_CACHE_V1';
  static const _modelCacheKey = 'MODEL_CACHE_V1';
  static const _cacheTtl = Duration(hours: 6);

  // In-memory cache for models to avoid repeated disk reads
  final Map<String, List<ModelDto>> _modelsMemoryCache = {};

  CacheService({GetStorage? storage}) : _storage = storage ?? GetStorage();

  // ==================== Brand Cache ====================

  /// Check if cached brands are still fresh (within TTL)
  bool isBrandCacheFresh() {
    try {
      final raw = _storage.read(_brandCacheKey);
      if (raw is Map && raw['storedAt'] is String) {
        final ts = DateTime.tryParse(raw['storedAt']);
        if (ts == null) return false;
        return DateTime.now().difference(ts) < _cacheTtl;
      }
    } catch (_) {}
    return false;
  }

  /// Save brands to cache with current timestamp
  void saveBrandCache(List<BrandDto> list) {
    try {
      final map = {
        'storedAt': DateTime.now().toIso8601String(),
        'items': list.map((b) => {'uuid': b.uuid, 'name': b.name}).toList(),
      };
      _storage.write(_brandCacheKey, map);
    } catch (_) {}
  }

  /// Load cached brands if available
  List<BrandDto>? loadBrandCache() {
    try {
      final raw = _storage.read(_brandCacheKey);
      if (raw is Map && raw['items'] is List) {
        final items = (raw['items'] as List)
            .whereType<Map>()
            .map((m) => BrandDto.fromJson(Map<String, dynamic>.from(m)))
            .where((b) => b.uuid.isNotEmpty)
            .toList();
        return items.isNotEmpty ? items : null;
      }
    } catch (_) {}
    return null;
  }

  /// Clear brand cache
  void clearBrandCache() {
    try {
      _storage.remove(_brandCacheKey);
    } catch (_) {}
  }

  // ==================== Model Cache ====================

  /// Check if cached models for a specific brand are still fresh
  bool isModelCacheFresh(String brandUuid) {
    try {
      final raw = _storage.read(_modelCacheKey);
      if (raw is Map && raw[brandUuid] is Map) {
        final entry = raw[brandUuid];
        final ts = DateTime.tryParse(entry['storedAt'] ?? '');
        if (ts == null) return false;
        return DateTime.now().difference(ts) < _cacheTtl;
      }
    } catch (_) {}
    return false;
  }

  /// Save models for a specific brand with current timestamp
  void saveModelCache(String brandUuid, List<ModelDto> list) {
    try {
      final raw = _storage.read(_modelCacheKey);
      Map<String, dynamic> cache = {};
      if (raw is Map) cache = Map<String, dynamic>.from(raw);

      cache[brandUuid] = {
        'storedAt': DateTime.now().toIso8601String(),
        'items': list.map((m) => {'uuid': m.uuid, 'name': m.name}).toList(),
      };

      _storage.write(_modelCacheKey, cache);
      _modelsMemoryCache[brandUuid] = list; // Also cache in memory
    } catch (_) {}
  }

  /// Load cached models for a specific brand
  /// First checks memory cache, then disk cache
  List<ModelDto>? loadModelCache(String brandUuid) {
    try {
      // Check memory cache first
      if (_modelsMemoryCache.containsKey(brandUuid)) {
        return _modelsMemoryCache[brandUuid];
      }

      // Check disk cache
      final raw = _storage.read(_modelCacheKey);
      if (raw is Map && raw[brandUuid] is Map) {
        final entry = raw[brandUuid];
        if (entry['items'] is List) {
          final items = (entry['items'] as List)
              .whereType<Map>()
              .map((m) => ModelDto.fromJson(Map<String, dynamic>.from(m)))
              .where((m) => m.uuid.isNotEmpty)
              .toList();

          if (items.isNotEmpty) {
            _modelsMemoryCache[brandUuid] = items; // Cache in memory
            return items;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Clear model cache for a specific brand
  void clearModelCache(String brandUuid) {
    try {
      _modelsMemoryCache.remove(brandUuid);
      final raw = _storage.read(_modelCacheKey);
      if (raw is Map) {
        final cache = Map<String, dynamic>.from(raw);
        cache.remove(brandUuid);
        _storage.write(_modelCacheKey, cache);
      }
    } catch (_) {}
  }

  /// Clear all model caches
  void clearAllModelCaches() {
    try {
      _modelsMemoryCache.clear();
      _storage.remove(_modelCacheKey);
    } catch (_) {}
  }

  /// Clear all caches (brands and models)
  void clearAll() {
    clearBrandCache();
    clearAllModelCaches();
  }
}
