import 'dart:async';

import 'package:auto_tm/domain/models/search_suggestion.dart';
import 'package:auto_tm/domain/repositories/search_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SearchScreenController extends GetxController {
  final searchTextController = TextEditingController();
  final searchTextFocus = FocusNode();
  final RxList<SearchSuggestion> hints = <SearchSuggestion>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int offset = 0;
  final int limit = 20;
  Timer? _debounce;

  SearchRepository get _searchRepository => Get.find<SearchRepository>();

  // Forward properties from Repository for UI compatibility
  RxBool get indexReady => _searchRepository.indexReady;
  RxBool get indexBuilding => _searchRepository.indexBuilding;

  @override
  void onClose() {
    searchTextController.dispose();
    searchTextFocus.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void debouncedSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchHints(reset: true);
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
      final results = await _searchRepository.search(
        query,
        offset: offset,
        limit: limit,
      );

      hints.addAll(results);

      if (indexReady.value) {
        hasMore.value = false;
      } else {
        if (results.length < limit) {
          hasMore.value = false;
        } else {
          offset += limit;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error: $e");
      }
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchTextController.clear();
    hints.clear();
    hasMore.value = false;
  }
}
