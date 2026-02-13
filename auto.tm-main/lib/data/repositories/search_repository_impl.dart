import 'dart:async';
import 'package:auto_tm/data/mappers/search_suggestion_mapper.dart';
import 'package:auto_tm/domain/models/search_suggestion.dart';
import 'package:auto_tm/domain/repositories/search_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class SearchRepositoryImpl implements SearchRepository {
  final ApiClient _apiClient;

  // Smart local index (brand + model pairs)
  final List<SearchSuggestion> _index = []; // full cached dataset
  @override
  final RxBool indexReady = false.obs;
  @override
  final RxBool indexBuilding = false.obs;
  DateTime? _lastIndexBuild;

  // Configuration for index size & rebuild frequency
  final int _maxIndexFetch = 10000;
  final Duration _indexTtl = const Duration(minutes: 30);

  SearchRepositoryImpl(this._apiClient) {
    ensureIndex();
  }

  @override
  Future<void> ensureIndex() async {
    if (indexReady.value) return;
    if (_lastIndexBuild != null &&
        DateTime.now().difference(_lastIndexBuild!) < _indexTtl) {
      return;
    }
    if (indexBuilding.value) return;
    indexBuilding.value = true;
    try {
      final resp = await _apiClient.dio.get(
        'brands/search',
        queryParameters: {'search': '', 'limit': _maxIndexFetch, 'offset': 0},
      );
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        final results = data is List
            ? data
            : (data is Map && data['results'] is List ? data['results'] : []);

        final list = (results as List)
            .map((e) => SearchSuggestionMapper.fromJson(Map<String, dynamic>.from(e)))
            .where((m) => m.brandLabel.isNotEmpty || m.modelLabel.isNotEmpty)
            .toList();
        _index
          ..clear()
          ..addAll(list);
        indexReady.value = true;
        _lastIndexBuild = DateTime.now();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[search] index error $e');
    } finally {
      indexBuilding.value = false;
    }
  }

  @override
  Future<List<SearchSuggestion>> search(String query, {int offset = 0, int limit = 20}) async {
    if (query.trim().isEmpty) return [];

    if (indexReady.value) {
      return _localSmartSearch(query);
    } else {
      return _apiSearch(query, offset: offset, limit: limit);
    }
  }

  Future<List<SearchSuggestion>> _apiSearch(String query, {required int offset, required int limit}) async {
    try {
      final response = await _apiClient.dio.get(
        'brands/search',
        queryParameters: {'search': query, 'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final results = data is List
            ? data
            : (data is Map && data['results'] is List ? data['results'] : []);

        return (results as List)
            .map((item) => SearchSuggestionMapper.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  List<SearchSuggestion> _localSmartSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final tokens = _tokenize(q);
    final scored = <_ScoredSuggestion>[];

    for (final m in _index) {
      final brand = m.brandLabel.toLowerCase();
      final model = m.modelLabel.toLowerCase();
      final combo = '$brand $model';
      final score = _score(tokens, brand, model, combo, m.compare.toLowerCase());
      if (score > 0) {
        scored.add(_ScoredSuggestion(m, score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(50).map((e) => e.suggestion).toList();
  }

  List<String> _tokenize(String q) {
    final normalized = q.replaceAllMapped(
      RegExp(r'([a-zA-Z])([0-9])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return normalized.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  }

  int _score(List<String> tokens, String brand, String model, String combo, String compare) {
    int total = 0;
    for (final t in tokens) {
      if (brand == t || model == t) {
        total += 120;
        continue;
      }
      if (brand.startsWith(t) || model.startsWith(t)) total += 90;
      if (combo.contains(t)) total += 60;
      if (compare.contains(t)) total += 50;
      if (t.length >= 2) {
        final dBrand = _levenshtein(t, brand, max: 2);
        final dModel = _levenshtein(t, model, max: 2);
        final dCombo = _levenshtein(t, combo, max: 2);
        final minD = [dBrand, dModel, dCombo].where((d) => d >= 0).fold<int>(999, (p, c) => c < p ? c : p);
        if (minD == 1) {
          total += 25;
        } else if (minD == 2) {
          total += 10;
        }
      }
    }
    return total;
  }

  int _levenshtein(String a, String b, {int max = 2}) {
    if ((a.length - b.length).abs() > max) return max + 1;
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
      if (minRow > max) return max + 1;
    }
    return dp[b.length];
  }

  int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
}

class _ScoredSuggestion {
  final SearchSuggestion suggestion;
  final int score;
  _ScoredSuggestion(this.suggestion, this.score);
}
