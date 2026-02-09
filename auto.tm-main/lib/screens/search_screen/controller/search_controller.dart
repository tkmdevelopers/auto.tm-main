import 'dart:async';

import 'package:auto_tm/screens/search_screen/model/search_model.dart';
import 'package:auto_tm/services/search_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SearchScreenController extends GetxController {
  final searchTextController = TextEditingController();
  final searchTextFocus = FocusNode();
  final RxList<SearchModel> hints = <SearchModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int offset = 0;
  final int limit = 20;
  Timer? _debounce;

  // Forward properties from Service for UI compatibility
  RxBool get indexReady => SearchService.to.indexReady;
  RxBool get indexBuilding => SearchService.to.indexBuilding;

  @override
  void onInit() {
    super.onInit();
    // SearchService handles index initialization automatically
  }

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
      // Delegate search logic to Service
      final results = await SearchService.to.search(
        query,
        offset: offset,
        limit: limit,
      );

      hints.addAll(results);

      if (SearchService.to.indexReady.value) {
        // Local search returns a fixed set of results (top 50) and stops.
        hasMore.value = false;
      } else {
        // API search pagination
        if (results.length < limit) {
          hasMore.value = false;
        } else {
          offset += limit;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchTextController.clear();
    hints.clear();
    // Reset hasMore state if needed, though usually typing reset it.
    // If the UI expects to clear results:
    hasMore.value = false;
  }
}

