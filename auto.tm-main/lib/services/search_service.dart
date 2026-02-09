import 'dart:async';
import 'dart:convert';

import 'package:auto_tm/screens/search_screen/model/search_model.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class SearchService extends GetxService {
  static SearchService get to => Get.find();

  // Smart local index (brand + model pairs)
  final List<SearchModel> _index = []; // full cached dataset
  final RxBool indexReady = false.obs;
  final RxBool indexBuilding = false.obs;
  DateTime? _lastIndexBuild;

  // Configuration for index size & rebuild frequency
  final int _maxIndexFetch = 10000; // upper bound; backend may cap it
  final Duration _indexTtl = const Duration(minutes: 30);

  @override
  void onInit() {
    super.onInit();
    _ensureIndex();
  }

  @visibleForTesting
  void setIndexForTesting(List<SearchModel> data) {
    _index.clear();
    _index.addAll(data);
    indexReady.value = true;
  }

  /// Ensures the local brand/model index is built for smart search.
  Future<void> _ensureIndex() async {
    if (indexReady.value) return;
    if (_lastIndexBuild != null &&
        DateTime.now().difference(_lastIndexBuild!) < _indexTtl) {
      return; // within TTL; keep existing
    }
    if (indexBuilding.value) return;
    indexBuilding.value = true;
    try {
      final resp = await ApiClient.to.dio.get(
        'brands/search',
        queryParameters: {'search': '', 'limit': _maxIndexFetch, 'offset': 0},
      );
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        // Robust handling: data could be List or Map {results: [...]}
        final results = data is List
            ? data
            : (data is Map && data['results'] is List ? data['results'] : []);
            
        final list = (results as List)
            .map((e) => SearchModel.fromJson(e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map)))
            .where((m) => m.brandLabel.isNotEmpty || m.modelLabel.isNotEmpty)
            .toList();
        _index
          ..clear()
          ..addAll(list);
        indexReady.value = true;
        _lastIndexBuild = DateTime.now();
      } else {
        if (kDebugMode) {
          print('[search] index fetch failed ${resp.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[search] index error $e');
    } finally {
      indexBuilding.value = false;
    }
  }

  /// Perform a search.
  /// If logic index is ready, performs a local smart search (returns top 50).
  /// Otherwise performs a remote API search with pagination.
  Future<List<SearchModel>> search(
    String query, {
    int offset = 0,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    if (indexReady.value) {
      // Local Smart Search
      // Note: Local search ignores offset/limit in the sense that it returns a ranked list.
      // But we can simulate it if needed. However, the original controller implementation
      // just returned 'take(50)' and disabled 'hasMore'.
      return _localSmartSearch(query);
    } else {
      // API Fallback Search
      return _apiSearch(query, offset: offset, limit: limit);
    }
  }

  Future<List<SearchModel>> _apiSearch(
    String query, {
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await ApiClient.to.dio.get(
        'brands/search',
        queryParameters: {
          'search': query,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // Handle direct array response which might be returned by the backend
        final results = data is List 
            ? data 
            : (data is Map && data['results'] is List ? data['results'] : []);
            
        return (results as List)
            .map((item) => SearchModel.fromJson(item is Map<String, dynamic> 
                ? item 
                : Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print("[SearchService] API Error: $e");
      }
    }
    return [];
  }

  List<SearchModel> _localSmartSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final tokens = _tokenize(q);
    final scored = <_ScoredModel>[];

    for (final m in _index) {
      final brand = m.brandLabel.toLowerCase();
      final model = m.modelLabel.toLowerCase();
      final combo = '$brand $model';
      final score = _score(
        tokens,
        brand,
        model,
        combo,
        m.compare.toLowerCase(),
      );
      if (score > 0) {
        scored.add(_ScoredModel(m, score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    
    // Limit to 50 for performance, consistent with original controller
    return scored.take(50).map((e) => e.model).toList();
  }

  List<String> _tokenize(String q) {
    // Insert space between letters followed by digits (e.g., x5 -> x 5)
    final normalized = q.replaceAllMapped(
      RegExp(r'([a-zA-Z])([0-9])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return normalized.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  }

  int _score(
    List<String> tokens,
    String brand,
    String model,
    String combo,
    String compare,
  ) {
    int total = 0;
    for (final t in tokens) {
      if (brand == t || model == t) {
        total += 120; // exact token
        continue;
      }
      if (brand.startsWith(t) || model.startsWith(t)) total += 90;
      if (combo.contains(t)) total += 60;
      if (compare.contains(t)) total += 50;
      // Fuzzy (distance <=2 for short tokens)
      if (t.length >= 2) {
        final dBrand = _levenshtein(t, brand, max: 2);
        final dModel = _levenshtein(t, model, max: 2);
        final dCombo = _levenshtein(t, combo, max: 2);
        final minD = [
          dBrand,
          dModel,
          dCombo,
        ].where((d) => d >= 0).fold<int>(999, (p, c) => c < p ? c : p);
        if (minD == 1)
          total += 25;
        else if (minD == 2)
          total += 10;
      }
    }
    return total;
  }

  int _levenshtein(String a, String b, {int max = 2}) {
    if ((a.length - b.length).abs() > max) return max + 1; // early prune
    final dp = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      int prev = dp[0];
      dp[0] = i;
      int minRow = dp[0];
      for (var j = 1; j <= b.length; j++) {
        final temp = dp[j];
        if (a[i - 1] == b[j - 1]) {
          dp[j] = prev;
        } else {
          dp[j] = 1 + _min3(prev, dp[j], dp[j - 1]);
        }
        prev = temp;
        if (dp[j] < minRow) minRow = dp[j];
      }
      if (minRow > max) return max + 1; // prune row
    }
    return dp[b.length];
  }

  int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
}

class _ScoredModel {
  final SearchModel model;
  final int score;
  _ScoredModel(this.model, this.score);
}
