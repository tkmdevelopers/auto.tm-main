import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/services/network/api_client.dart';

/// Single source-of-truth for brand & model data: fetching, caching,
/// filtering, and UUID → human-name resolution.
///
/// Shared across PostController, FilterController, or any other feature that
/// needs brand/model lists.
class BrandModelService extends GetxService {
  static BrandModelService get to => Get.find();

  final ApiClient _apiClient;
  final GetStorage _box;

  BrandModelService(this._apiClient) : _box = GetStorage();

  /// Test constructor that allows injecting a mock GetStorage.
  BrandModelService.withStorage(this._apiClient, this._box);

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  final RxList<BrandDto> brands = <BrandDto>[].obs;
  final RxList<ModelDto> models = <ModelDto>[].obs;

  final RxBool isLoadingBrands = false.obs;
  final RxBool isLoadingModels = false.obs;
  final RxBool brandsFromCache = false.obs;
  final RxBool modelsFromCache = false.obs;

  final RxString brandSearchQuery = ''.obs;
  final RxString modelSearchQuery = ''.obs;

  /// Bumped whenever a late-resolved model name arrives so UI can rebuild.
  final RxInt modelNameResolutionTick = 0.obs;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  final Map<String, String> _brandNameById = {};
  final Map<String, String> _modelNameById = {};
  final Set<String> _fetchedBrandModels = <String>{};
  final Map<String, List<ModelDto>> _modelsMemoryCache = {};

  static const _brandCacheKey = 'BRAND_CACHE_V1';
  static const _modelCacheKey = 'MODEL_CACHE_V1';
  static const _cacheTtl = Duration(hours: 6);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _hydrateBrandCache();
    _rebuildNameLookups();
  }

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  List<BrandDto> get filteredBrands {
    if (brandSearchQuery.value.isEmpty) return brands;
    return brands
        .where(
          (b) => b.name.toLowerCase().contains(
            brandSearchQuery.value.toLowerCase(),
          ),
        )
        .toList();
  }

  List<ModelDto> get filteredModels {
    if (modelSearchQuery.value.isEmpty) return models;
    return models
        .where(
          (m) => m.name.toLowerCase().contains(
            modelSearchQuery.value.toLowerCase(),
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  Future<void> fetchBrands({bool forceRefresh = false}) async {
    if (!forceRefresh && brands.isNotEmpty) return;

    isLoadingBrands.value = true;
    try {
      if (!forceRefresh && brands.isNotEmpty && brandsFromCache.value) {
        if (_isBrandCacheFresh()) {
          isLoadingBrands.value = false;
          return;
        }
      }

      final resp = await _apiClient.dio
          .get('brands')
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && resp.data != null) {
        final parsed = _parseBrandList(resp.data);
        brands.assignAll(parsed);
        brandsFromCache.value = false;
        _saveBrandCache(parsed);
        _rebuildNameLookups();
      } else if (resp.statusCode == 401) {
        _fallbackBrandCache();
      } else {
        _fallbackBrandCache();
      }
    } on TimeoutException {
      _fallbackBrandCache();
    } catch (_) {
      _fallbackBrandCache();
    } finally {
      isLoadingBrands.value = false;
    }
  }

  Future<void> fetchModels(
    String brandUuid, {
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (brandUuid.isEmpty) return;

    if (!forceRefresh && models.isNotEmpty) {
      // Already showing models – skip unless brand changed
      // (caller should clear models if brand changes)
    }

    if (showLoading) isLoadingModels.value = true;

    try {
      if (!forceRefresh) {
        final cached = _hydrateModelCache(brandUuid);
        if (cached != null && cached.isNotEmpty) {
          models.assignAll(cached);
          modelsFromCache.value = true;
          if (_isModelCacheFresh(brandUuid)) {
            isLoadingModels.value = false;
            _rebuildNameLookups();
            return;
          }
        }
      }

      final resp = await _apiClient.dio
          .get('models', queryParameters: {'filter': brandUuid})
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && resp.data != null) {
        final parsed = _parseModelList(resp.data);
        models.assignAll(parsed);
        modelsFromCache.value = false;
        _saveModelCache(brandUuid, parsed);
        _rebuildNameLookups();
      } else {
        _fallbackModelCache(brandUuid);
      }
    } on TimeoutException {
      _fallbackModelCache(brandUuid);
    } catch (_) {
      _fallbackModelCache(brandUuid);
    } finally {
      if (showLoading) isLoadingModels.value = false;
    }
  }

  /// Pre-warm both brand + model caches and rebuild name lookups.
  Future<void> ensureCachesLoaded() async {
    if (_brandNameById.isNotEmpty && _modelNameById.isNotEmpty) return;
    try {
      await Future.wait([_maybeFetchBrands(), _maybeFetchModels()]);
      _rebuildNameLookups();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Name resolution (UUID → human name)
  // ---------------------------------------------------------------------------

  String resolveBrandName(String idOrName) {
    if (idOrName.isEmpty) return '';
    if (!_looksLikeUuid(idOrName)) return idOrName;
    return _brandNameById[idOrName] ?? idOrName;
  }

  String resolveModelName(String idOrName) {
    if (idOrName.isEmpty) return '';
    if (!_looksLikeUuid(idOrName)) return idOrName;
    final existing = _modelNameById[idOrName];
    if (existing != null) return existing;
    // Lazy retrieval
    _maybeFetchModels().then((_) {
      if (_modelNameById.containsKey(idOrName)) {
        modelNameResolutionTick.value++;
      }
    });
    return idOrName; // temporary fallback until resolved
  }

  /// Resolve model when we also know its brandId.
  String resolveModelWithBrand(String modelId, String brandId) {
    if (modelId.isEmpty) return '';
    if (!_looksLikeUuid(modelId)) return modelId;
    final existing = _modelNameById[modelId];
    if (existing != null) return existing;
    if (brandId.isNotEmpty &&
        _looksLikeUuid(brandId) &&
        !_fetchedBrandModels.contains(brandId)) {
      _fetchedBrandModels.add(brandId);
      Future.microtask(() async {
        await fetchModels(brandId, showLoading: false);
        await Future.delayed(const Duration(milliseconds: 200));
        _rebuildNameLookups();
        if (_modelNameById.containsKey(modelId)) {
          modelNameResolutionTick.value++;
        }
      });
    }
    return modelId;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers – parsing
  // ---------------------------------------------------------------------------

  List<BrandDto> _parseBrandList(dynamic decoded) {
    try {
      final listCandidate = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] is List)
          ? decoded['data']
          : [];
      if (listCandidate is! List) return [];
      return listCandidate
          .whereType<Map>()
          .map((m) => BrandDto.fromJson(Map<String, dynamic>.from(m)))
          .where((b) => b.uuid.isNotEmpty && b.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<ModelDto> _parseModelList(dynamic decoded) {
    try {
      final listCandidate = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] is List)
          ? decoded['data']
          : [];
      if (listCandidate is! List) return [];
      return listCandidate
          .whereType<Map>()
          .map((m) => ModelDto.fromJson(Map<String, dynamic>.from(m)))
          .where((m) => m.uuid.isNotEmpty && m.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers – cache management
  // ---------------------------------------------------------------------------

  bool _isBrandCacheFresh() {
    try {
      final raw = _box.read(_brandCacheKey);
      if (raw is Map && raw['storedAt'] is String) {
        final ts = DateTime.tryParse(raw['storedAt']);
        if (ts == null) return false;
        return DateTime.now().difference(ts) < _cacheTtl;
      }
    } catch (_) {}
    return false;
  }

  bool _isModelCacheFresh(String brandUuid) {
    try {
      final raw = _box.read(_modelCacheKey);
      if (raw is Map && raw[brandUuid] is Map) {
        final entry = raw[brandUuid];
        final ts = DateTime.tryParse(entry['storedAt'] ?? '');
        if (ts == null) return false;
        return DateTime.now().difference(ts) < _cacheTtl;
      }
    } catch (_) {}
    return false;
  }

  void _saveBrandCache(List<BrandDto> list) {
    try {
      _box.write(_brandCacheKey, {
        'storedAt': DateTime.now().toIso8601String(),
        'items': list.map((b) => {'uuid': b.uuid, 'name': b.name}).toList(),
      });
    } catch (_) {}
  }

  void _saveModelCache(String brandUuid, List<ModelDto> list) {
    try {
      final raw = _box.read(_modelCacheKey);
      Map<String, dynamic> cache = {};
      if (raw is Map) cache = Map<String, dynamic>.from(raw);
      cache[brandUuid] = {
        'storedAt': DateTime.now().toIso8601String(),
        'items': list.map((m) => {'uuid': m.uuid, 'name': m.name}).toList(),
      };
      _box.write(_modelCacheKey, cache);
      _modelsMemoryCache[brandUuid] = list;
    } catch (_) {}
  }

  void _hydrateBrandCache() {
    try {
      final raw = _box.read(_brandCacheKey);
      if (raw is Map && raw['items'] is List) {
        final fresh = _isBrandCacheFresh();
        final items = (raw['items'] as List)
            .whereType<Map>()
            .map((m) => BrandDto.fromJson(Map<String, dynamic>.from(m)))
            .where((b) => b.uuid.isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          brands.assignAll(items);
          brandsFromCache.value = true;
          if (!fresh) {
            Future.microtask(() => fetchBrands(forceRefresh: true));
          }
        }
      }
    } catch (_) {}
  }

  List<ModelDto>? _hydrateModelCache(String brandUuid) {
    try {
      if (_modelsMemoryCache.containsKey(brandUuid)) {
        return _modelsMemoryCache[brandUuid];
      }
      final raw = _box.read(_modelCacheKey);
      if (raw is Map && raw[brandUuid] is Map) {
        final entry = raw[brandUuid];
        final items =
            (entry['items'] as List?)
                ?.whereType<Map>()
                .map((m) => ModelDto.fromJson(Map<String, dynamic>.from(m)))
                .where((m) => m.uuid.isNotEmpty)
                .toList() ??
            [];
        _modelsMemoryCache[brandUuid] = items;
        return items;
      }
    } catch (_) {}
    return null;
  }

  void _fallbackBrandCache() {
    if (brands.isEmpty) _hydrateBrandCache();
  }

  void _fallbackModelCache(String brandUuid) {
    if (models.isEmpty) {
      final cached = _hydrateModelCache(brandUuid) ?? [];
      if (cached.isNotEmpty) models.assignAll(cached);
    }
  }

  void _rebuildNameLookups() {
    for (final b in brands) {
      if (b.uuid.isNotEmpty && b.name.isNotEmpty) {
        _brandNameById[b.uuid] = b.name;
      }
    }
    for (final m in models) {
      if (m.uuid.isNotEmpty && m.name.isNotEmpty) {
        _modelNameById[m.uuid] = m.name;
      }
    }
  }

  bool _looksLikeUuid(String s) => RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(s);

  Future<void> _maybeFetchBrands() async {
    if (brands.isNotEmpty) return;
    try {
      final resp = await _apiClient.dio.get('brands');
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        if (data is List) {
          brands.assignAll(
            data
                .map(
                  (e) =>
                      e is Map<String, dynamic> ? BrandDto.fromJson(e) : null,
                )
                .whereType<BrandDto>()
                .toList(),
          );
        } else {
          final parsed = _parseBrandList(data);
          if (parsed.isNotEmpty) brands.assignAll(parsed);
        }
      }
    } catch (_) {}
  }

  Future<void> _maybeFetchModels() async {
    if (models.isNotEmpty) return;
    try {
      final resp = await _apiClient.dio.get('models');
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        if (data is List) {
          models.assignAll(
            data
                .map(
                  (e) =>
                      e is Map<String, dynamic> ? ModelDto.fromJson(e) : null,
                )
                .whereType<ModelDto>()
                .toList(),
          );
        } else {
          final parsed = _parseModelList(data);
          if (parsed.isNotEmpty) models.assignAll(parsed);
        }
      }
    } catch (_) {}
  }
}
