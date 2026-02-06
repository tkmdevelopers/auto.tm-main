import 'dart:async';
import 'dart:convert';

import 'package:auto_tm/screens/search_screen/model/search_model.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:auto_tm/utils/key.dart';

// class SearchScreenController extends GetxController {

// final TextEditingController searchController = TextEditingController();
//   final FocusNode searchFocus = FocusNode();
//   final box = GetStorage();
//   void unFocus() {
//     searchFocus.unfocus();
//   }

//   final isSearchLoading = false.obs;
//   final searchResults = <Post>[].obs;

//   // Replace with your API endpoint
//   final String searchApiUrl = ApiKey.searchPostsKey;

//   void searchProducts(String query) async {
//     if (query.isEmpty) {
//       searchResults.clear();
//       return;
//     }

//     isSearchLoading.value = true;

//     try {
//       final response = await http.get(Uri.parse('$searchApiUrl?brand=true&model=true&photo=true&subscription=true&search=$query'),headers: {
//           "Content-Type": "application/json",
//           // 'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
//         },);

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         // final products = (data['products'] as List)
//         //     .map((item) => Product.fromJson(item))
//         //     .toList();
//         searchResults.value = data.map((item) => Post.fromJson(item)).toList();
//       } else {
//         searchResults.clear();
//       }
//     } catch (e) {
//       searchResults.clear();
//     } finally {
//       isSearchLoading.value = false;
//     }
//   }

//   Future<bool> refreshAccessToken() async {
//     try {
//       final refreshToken = box.read('REFRESH_TOKEN');

//       final response = await http.get(
//         Uri.parse(ApiKey.refreshTokenKey),
//         headers: {
//           "Content-Type": "application/json",
//           'Authorization': 'Bearer $refreshToken'
//         },
//       );

//       if (response.statusCode == 200 && response.body.isNotEmpty) {
//         final data = jsonDecode(response.body);
//         final newAccessToken = data['accessToken'];
//         if (newAccessToken != null) {
//           box.remove('ACCESS_TOKEN');
//           box.write('ACCESS_TOKEN', newAccessToken);
//           return true; // Indicate successful refresh
//         } else {
//           return false; // Indicate failed refresh
//         }
//       } if (response.statusCode == 406) {
//         Get.offAllNamed('/login');
//         return false; // Indicate failed refresh
//       } else {
//         return false; // Indicate failed refresh
//       }
//     } catch (e) {
//       return false; // Indicate failed refresh
//     }
//   }

//   void clearSearch() {
//     searchResults.clear();
//     searchController.clear();
//     searchFocus.unfocus();
//   }

//   @override
//   void onClose() {
//     searchController.dispose();
//     searchFocus.dispose();
//     super.onClose();
//   }
// }

class SearchScreenController extends GetxController {
  final searchTextController = TextEditingController();
  final searchTextFocus = FocusNode();
  final RxList<SearchModel> hints = <SearchModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int offset = 0;
  final int limit = 20;
  Timer? _debounce;

  // Smart local index (brand + model pairs) ---------------------------------
  final List<SearchModel> _index = []; // full cached dataset
  final RxBool indexBuilding = false.obs;
  final RxBool indexReady = false.obs;
  DateTime? _lastIndexBuild;

  // Configuration for index size & rebuild frequency
  final int _maxIndexFetch = 10000; // upper bound; backend may cap it
  final Duration _indexTtl = const Duration(minutes: 30);

  @override
  void onInit() {
    super.onInit();
    _ensureIndex();
  }

  void debouncedSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (indexReady.value) {
        _localSmartSearch();
      } else {
        searchHints(reset: true); // fallback while index builds
      }
    });
  }

  Future<void> searchHints({bool reset = false}) async {
    final query = searchTextController.text.trim();
    if (query.isEmpty) {
      hints.clear();
      hasMore.value = false;
      return;
    }

    if (isLoading.value) return;

    isLoading.value = true;

    if (reset) {
      offset = 0;
      hints.clear();
      hasMore.value = true;
    }

    try {
      final accessToken = await TokenStore.to.accessToken;
      final response = await http.get(
        Uri.parse(
          '${ApiKey.apiKey}brands/search?search=$query&limit=$limit&offset=$offset',
        ),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<SearchModel> fetched = (data['results'] as List)
            .map((item) => SearchModel.fromJson(item))
            .toList();

        hints.addAll(fetched);
        if (fetched.length < limit) {
          hasMore.value = false;
        } else {
          offset += limit;
        }
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }

    isLoading.value = false;
  }

  // --- Index Management -----------------------------------------------------
  Future<void> _ensureIndex() async {
    if (indexReady.value) return;
    if (_lastIndexBuild != null &&
        DateTime.now().difference(_lastIndexBuild!) < _indexTtl) {
      return; // within TTL; keep existing
    }
    if (indexBuilding.value) return;
    indexBuilding.value = true;
    try {
      // Try broad fetch with empty search (backend should return list)
      final uri = Uri.parse(
        '${ApiKey.apiKey}brands/search?search=&limit=$_maxIndexFetch&offset=0',
      );
      final accessToken = await TokenStore.to.accessToken;
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = (data['results'] as List)
            .map((e) => SearchModel.fromJson(e))
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

  // --- Local Smart Search ---------------------------------------------------
  void _localSmartSearch() {
    final q = searchTextController.text.trim().toLowerCase();
    if (q.isEmpty) {
      hints.clear();
      return;
    }
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
    // Limit suggestions to 50 for performance
    hints.assignAll(scored.take(50).map((e) => e.model));
    hasMore.value = false; // local suggestions fully loaded
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
