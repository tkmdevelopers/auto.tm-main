import 'dart:async';
import 'dart:isolate';
import 'package:auto_tm/data/datasources/local/local_storage.dart';
import 'package:auto_tm/data/mappers/brand_mapper.dart';
import 'package:auto_tm/data/mappers/car_model_mapper.dart';
import 'package:auto_tm/domain/models/brand.dart';
import 'package:auto_tm/domain/models/car_model.dart';
import 'package:auto_tm/domain/repositories/brand_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';

class BrandRepositoryImpl implements BrandRepository {
  final ApiClient _apiClient;
  final LocalStorage _storage;

  static const _brandCacheKey = 'BRAND_CACHE_V1';
  static const _modelCacheKey = 'MODEL_CACHE_V1';
  static const _historyKey = 'brand_history';
  static const _cacheTtl = Duration(hours: 6);

  // Name lookups
  final Map<String, String> _brandNameById = {};
  final Map<String, String> _modelNameById = {};
  final Set<String> _fetchedBrandModels = <String>{};
  final Map<String, List<CarModel>> _modelsMemoryCache = {};

  @override
  final RxList<Brand> brands = <Brand>[].obs;
  @override
  final RxList<CarModel> models = <CarModel>[].obs;
  @override
  final RxBool isLoadingBrands = false.obs;
  @override
  final RxBool isLoadingModels = false.obs;
  @override
  final RxString brandSearchQuery = ''.obs;
  @override
  final RxString modelSearchQuery = ''.obs;
  @override
  final RxInt nameResolutionTick = 0.obs;

  BrandRepositoryImpl(this._apiClient, {LocalStorage? storage})
    : _storage = storage ?? GetStorageImpl() {
    _hydrateBrandCache();
    _rebuildNameLookups();
  }

  // ---------------------------------------------------------------------------
  // Computed
  // ---------------------------------------------------------------------------

  @override
  List<Brand> get filteredBrands {
    if (brandSearchQuery.value.isEmpty) return brands;
    final q = brandSearchQuery.value.toLowerCase();
    return brands.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  @override
  List<CarModel> get filteredModels {
    if (modelSearchQuery.value.isEmpty) return models;
    final q = modelSearchQuery.value.toLowerCase();
    return models.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  // ---------------------------------------------------------------------------
  // Data Fetching
  // ---------------------------------------------------------------------------

  @override
  Future<void> fetchBrands({bool forceRefresh = false}) async {
    if (!forceRefresh && brands.isNotEmpty && _isBrandCacheFresh()) return;

    isLoadingBrands.value = true;
    try {
      final resp = await _apiClient.dio.get('brands');
      if (resp.statusCode == 200 && resp.data != null) {
        final List<dynamic> raw =
            resp.data is List ? resp.data : (resp.data['data'] ?? []);
        final parsed = raw
            .whereType<Map>()
            .map((m) => BrandMapper.fromJson(Map<String, dynamic>.from(m)))
            .where((b) => b.uuid.isNotEmpty)
            .toList();

        if (parsed.isNotEmpty) {
          brands.assignAll(parsed);
          _saveBrandCache(parsed);
          _rebuildNameLookups();
        }
      }
    } catch (_) {
      _fallbackBrandCache();
    } finally {
      isLoadingBrands.value = false;
    }
  }

  @override
  Future<void> fetchModels(
    String brandUuid, {
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (brandUuid.isEmpty) return;
    if (showLoading) isLoadingModels.value = true;

    try {
      if (!forceRefresh) {
        final cached = _hydrateModelCache(brandUuid);
        if (cached != null && cached.isNotEmpty) {
          models.assignAll(cached);
          if (_isModelCacheFresh(brandUuid)) {
            if (showLoading) isLoadingModels.value = false;
            _rebuildNameLookups();
            return;
          }
        }
      }

      final resp = await _apiClient.dio.get(
        'models',
        queryParameters: {'filter': brandUuid},
      );
      if (resp.statusCode == 200 && resp.data != null) {
        final List<dynamic> raw =
            resp.data is List ? resp.data : (resp.data['data'] ?? []);
        final parsed = raw
            .whereType<Map>()
            .map((m) => CarModelMapper.fromJson(Map<String, dynamic>.from(m)))
            .where((m) => m.uuid.isNotEmpty)
            .toList();

        if (parsed.isNotEmpty) {
          models.assignAll(parsed);
          _saveModelCache(brandUuid, parsed);
          _rebuildNameLookups();
        }
      }
    } catch (_) {
      _fallbackModelCache(brandUuid);
    } finally {
      if (showLoading) isLoadingModels.value = false;
    }
  }

  @override
  Future<List<Brand>> fetchBrandsByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return [];
    try {
      final response = await _apiClient.dio.post(
        'brands/history',
        data: {'uuids': uuids, 'post': false},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          rawList = data['rows'] ?? data['data'] ?? [];
        }

        return await Isolate.run(() {
          final list = List<Map<String, dynamic>>.from(rawList);
          return list.map((json) => BrandMapper.fromJson(json)).toList();
        });
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> ensureCachesLoaded() async {
    if (_brandNameById.isNotEmpty && _modelNameById.isNotEmpty) return;
    try {
      await Future.wait([fetchBrands(), fetchModels('')]);
      _rebuildNameLookups();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  @override
  String resolveBrandName(String idOrName) {
    if (idOrName.isEmpty) return '';
    if (!_looksLikeUuid(idOrName)) return idOrName;
    return _brandNameById[idOrName] ?? idOrName;
  }

  @override
  String resolveModelName(String idOrName) {
    if (idOrName.isEmpty) return '';
    if (!_looksLikeUuid(idOrName)) return idOrName;
    final existing = _modelNameById[idOrName];
    if (existing != null) return existing;

    fetchModels('', showLoading: false).then((_) {
      if (_modelNameById.containsKey(idOrName)) {
        nameResolutionTick.value++;
      }
    });
    return idOrName;
  }

  @override
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
          nameResolutionTick.value++;
        }
      });
    }
    return modelId;
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  @override
  List<dynamic> getLocalHistory() {
    return _storage.read<List>(_historyKey) ?? [];
  }

  @override
  Future<void> saveLocalHistory(List<dynamic> items) {
    return _storage.write(_historyKey, items);
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  bool _isBrandCacheFresh() {
    final raw = _storage.read(_brandCacheKey);
    if (raw is Map && raw['storedAt'] is String) {
      final ts = DateTime.tryParse(raw['storedAt']);
      return ts != null && DateTime.now().difference(ts) < _cacheTtl;
    }
    return false;
  }

  bool _isModelCacheFresh(String brandUuid) {
    final raw = _storage.read(_modelCacheKey);
    if (raw is Map && raw[brandUuid] is Map) {
      final entry = raw[brandUuid];
      final ts = DateTime.tryParse(entry['storedAt'] ?? '');
      return ts != null && DateTime.now().difference(ts) < _cacheTtl;
    }
    return false;
  }

  void _saveBrandCache(List<Brand> list) {
    _storage.write(_brandCacheKey, {
      'storedAt': DateTime.now().toIso8601String(),
      'items': list.map((b) => {'uuid': b.uuid, 'name': b.name}).toList(),
    });
  }

  void _saveModelCache(String brandUuid, List<CarModel> list) {
    final raw = _storage.read(_modelCacheKey);
    Map<String, dynamic> cache = {};
    if (raw is Map) cache = Map<String, dynamic>.from(raw);
    cache[brandUuid] = {
      'storedAt': DateTime.now().toIso8601String(),
      'items': list.map((m) => {'uuid': m.uuid, 'name': m.name}).toList(),
    };
    _storage.write(_modelCacheKey, cache);
    _modelsMemoryCache[brandUuid] = list;
  }

  void _hydrateBrandCache() {
    final raw = _storage.read(_brandCacheKey);
    if (raw is Map && raw['items'] is List) {
      final isFresh = _isBrandCacheFresh();
      final items = (raw['items'] as List)
          .whereType<Map>()
          .map(
            (m) => Brand(
              uuid: m['uuid']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
            ),
          )
          .where((b) => b.uuid.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        brands.assignAll(items);
        if (!isFresh) Future.microtask(() => fetchBrands(forceRefresh: true));
      }
    }
  }

  List<CarModel>? _hydrateModelCache(String brandUuid) {
    if (_modelsMemoryCache.containsKey(brandUuid)) return _modelsMemoryCache[brandUuid];
    final raw = _storage.read(_modelCacheKey);
    if (raw is Map && raw[brandUuid] is Map) {
      final entry = raw[brandUuid];
      final items =
          (entry['items'] as List?)
              ?.whereType<Map>()
              .map(
                (m) => CarModel(
                  uuid: m['uuid']?.toString() ?? '',
                  name: m['name']?.toString() ?? '',
                ),
              )
              .where((m) => m.uuid.isNotEmpty)
              .toList() ??
          [];
      _modelsMemoryCache[brandUuid] = items;
      return items;
    }
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
      if (b.uuid.isNotEmpty && b.name.isNotEmpty) _brandNameById[b.uuid] = b.name;
    }
    for (final m in models) {
      if (m.uuid.isNotEmpty && m.name.isNotEmpty) _modelNameById[m.uuid] = m.name;
    }
  }

  bool _looksLikeUuid(String s) => RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(s);
}
