import 'dart:async';

import 'package:auto_tm/services/brand_model_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/post_filter.dart';
import 'package:auto_tm/services/filter_service.dart';
import 'package:auto_tm/models/post_dtos.dart';

class FilterController extends GetxController {
  final TextEditingController milleageController = TextEditingController();
  final TextEditingController enginepowerController = TextEditingController();
  final TextEditingController brandSearchController = TextEditingController();
  final TextEditingController modelSearchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final box = GetStorage();
  var offset = 0;
  final int limit = 20;
  // Tracks whether user has already opened the results page in this session.
  final RxBool hasViewedResults = false.obs;

  // Debounce timer for auto-search
  Timer? _debounce;
  void debouncedSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchProducts();
    });
  }

  // Brand/model data – delegated to BrandModelService
  late final BrandModelService _brandModelSvc;
  FilterController({BrandModelService? brandModelSvc}) : _brandModelSvc = brandModelSvc ?? BrandModelService.to;

  RxList<BrandDto> get brands => _brandModelSvc.brands;
  RxList<ModelDto> get models => _brandModelSvc.models;
  RxBool get isLoadingBrands => _brandModelSvc.isLoadingBrands;
  RxBool get isLoadingModels => _brandModelSvc.isLoadingModels;
  final RxBool isLoading = false.obs;

  // Selection state
  final RxString selectedBrandUuid = ''.obs;
  final RxString selectedModelUuid = ''.obs;
    final RxString selectedBrandName = ''.obs;
    final RxString selectedModelName = ''.obs;
    
    // Aliases for test compatibility
    RxString get selectedBrand => selectedBrandName;
    RxString get selectedModel => selectedModelName;
  
    final RxString selectedCategoryUuid = ''.obs;
  
  final RxString selectedCategoryName = ''.obs;

  // Filter state
  var selectedCountry = 'Local'.obs;
  var condition = 'All'.obs;
  var location = ''.obs; // Specific city
  var transmission = ''.obs;
  var selectedColor = ''.obs;
  var enginePower = ''.obs;
  var milleage = ''.obs;
  var exchange = false.obs;
  var credit = false.obs;
  final RxList<String> premium = <String>[].obs;

  // Range filters
  final RxString minYear = ''.obs;
  final RxString maxYear = ''.obs;
  final RxnInt minPrice = RxnInt();
  final RxnInt maxPrice = RxnInt();

  // Slider bounds
  final RxInt yearLowerBound = 1990.obs;
  final RxInt yearUpperBound = DateTime.now().year.obs;
  final Rx<RangeValues> yearRange = RangeValues(
    1990,
    DateTime.now().year.toDouble(),
  ).obs;
  final RxInt priceLowerBound = 0.obs;
  final RxInt priceUpperBound = 1000000.obs;
  final Rx<RangeValues> priceRange = const RangeValues(0, 1000000).obs;

  // Year range accessors
  String get effectiveMinYear => minYear.value.isNotEmpty ? minYear.value : (yearRange.value.start != yearLowerBound.value ? yearRange.value.start.round().toString() : '');
  String get effectiveMaxYear => maxYear.value.isNotEmpty ? maxYear.value : (yearRange.value.end != yearUpperBound.value ? yearRange.value.end.round().toString() : '');

  final RxString selectedSortOption = 'createdAt_desc'.obs;
  final RxBool isSearchLoading = false.obs;
  final RxList<Post> searchResults = <Post>[].obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // _brandModelSvc already assigned via constructor or late init fallback
    
    // Sync isLoading with service states
    ever(isLoadingBrands, (val) => isLoading.value = val || isLoadingModels.value);
    ever(isLoadingModels, (val) => isLoading.value = val || isLoadingBrands.value);

    // Listen to text controllers for auto-search
    milleageController.addListener(debouncedSearch);
    enginepowerController.addListener(debouncedSearch);

    // Listen to Rx variables
    ever(transmission, (_) => debouncedSearch());
    ever(condition, (_) => debouncedSearch());
    ever(exchange, (_) => debouncedSearch());
    ever(credit, (_) => debouncedSearch());
    ever(minYear, (_) => debouncedSearch());
    ever(maxYear, (_) => debouncedSearch());
    ever(minPrice, (_) => debouncedSearch());
    ever(maxPrice, (_) => debouncedSearch());
    ever(priceRange, (_) => debouncedSearch());
    ever(yearRange, (_) => debouncedSearch());
    ever(selectedBrandUuid, (_) => debouncedSearch());
    ever(selectedModelUuid, (_) => debouncedSearch());
    ever(selectedCategoryUuid, (_) => debouncedSearch());
    ever(location, (_) => debouncedSearch());
    ever(selectedCountry, (_) => debouncedSearch());

    // Initial fetch
    searchProducts();

    // Setup scroll listener
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isSearchLoading.value) {
        searchProducts(loadMore: true);
      }
    });
  }

  void updateSortOption(String newSortOption) {
    if (selectedSortOption.value != newSortOption) {
      selectedSortOption.value = newSortOption;
      searchProducts();
    }
  }

  void clearFilters({bool includeBrandModel = false}) {
    transmission.value = '';
    enginepowerController.clear();
    milleageController.clear();
    selectedColor.value = '';
    condition.value = 'All';
    exchange.value = false;
    credit.value = false;
    premium.clear();
    minYear.value = '';
    maxYear.value = '';
    yearRange.value = RangeValues(
      yearLowerBound.value.toDouble(),
      yearUpperBound.value.toDouble(),
    );
    location.value = '';
    selectedCountry.value = 'Local';
    minPrice.value = null;
    maxPrice.value = null;
    priceRange.value = RangeValues(
      priceLowerBound.value.toDouble(),
      priceUpperBound.value.toDouble(),
    );
    if (includeBrandModel) {
      selectedBrandUuid.value = '';
      selectedModelUuid.value = '';
      selectedBrandName.value = '';
      selectedModelName.value = '';
      selectedCategoryUuid.value = '';
      selectedCategoryName.value = '';
    }
  }

  void togglePremium(String uuid) {
    if (premium.contains(uuid)) {
      premium.remove(uuid);
    } else {
      premium.add(uuid);
    }
    debouncedSearch();
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedBrandUuid.value.isNotEmpty) count++;
    if (selectedModelUuid.value.isNotEmpty) count++;
    if (selectedCategoryUuid.value.isNotEmpty) count++;
    if (selectedCountry.value != 'Local' || location.value.isNotEmpty) count++;
    if (transmission.value.isNotEmpty) count++;
    if (credit.value) count++;
    if (exchange.value) count++;
    if (minYear.value.isNotEmpty || maxYear.value.isNotEmpty) count++;
    if (milleageController.text.isNotEmpty) count++;
    if (enginepowerController.text.isNotEmpty) count++;
    if (selectedColor.value.isNotEmpty) count++;
    if (premium.isNotEmpty) count++;
    if (condition.value.isNotEmpty && condition.value != 'All') count++;
    return count;
  }

  Map<String, dynamic> buildQueryParams() {
    final sort = _parseSortOption(selectedSortOption.value);
    
    final filter = PostFilter(
      brandFilter: selectedBrandUuid.value.isNotEmpty ? selectedBrandUuid.value : null,
      modelFilter: selectedModelUuid.value.isNotEmpty ? selectedModelUuid.value : null,
      categoryFilter: selectedCategoryUuid.value.isNotEmpty ? selectedCategoryUuid.value : null,
      region: selectedCountry.value != 'Local' ? selectedCountry.value : null,
      location: (selectedCountry.value == 'Local' && location.value.isNotEmpty) ? location.value : null,
      color: selectedColor.value.isNotEmpty ? selectedColor.value : null,
      credit: credit.value ? true : null,
      exchange: exchange.value ? true : null,
      transmission: transmission.value.isNotEmpty ? transmission.value : null,
      enginePower: enginepowerController.text.isNotEmpty ? enginepowerController.text : null,
      milleage: milleageController.text.isNotEmpty ? milleageController.text : null,
      condition: condition.value != 'All' ? condition.value : null,
      minYear: minYear.value.isNotEmpty ? minYear.value : (yearRange.value.start != yearLowerBound.value ? yearRange.value.start.round().toString() : null),
      maxYear: maxYear.value.isNotEmpty ? maxYear.value : (yearRange.value.end != yearUpperBound.value ? yearRange.value.end.round().toString() : null),
      minPrice: minPrice.value != null ? minPrice.value.toString() : (priceRange.value.start != priceLowerBound.value ? priceRange.value.start.round().toString() : null),
      maxPrice: maxPrice.value != null ? maxPrice.value.toString() : (priceRange.value.end != priceUpperBound.value ? priceRange.value.end.round().toString() : null),
      subFilter: premium.isNotEmpty ? premium.toList() : null,
      sortBy: sort['sortBy'],
      sortAs: sort['sortAs'],
    );

    Map<String, dynamic> params = {
      'brand': true,
      'model': true,
      'photo': true,
      'subscription': true,
      'status': true,
      'offset': offset,
      'limit': limit,
      ...filter.toQueryParams(),
    };

    return params;
  }

  String buildQuery() {
    final params = buildQueryParams();
    // Remove default boolean flags for cleaner test output if they are true
    params.removeWhere((k, v) => (k == 'brand' || k == 'model' || k == 'photo' || k == 'subscription' || k == 'status') && v == true);
    // Remove pagination for cleaner test output
    params.remove('offset');
    params.remove('limit');
    // Remove default sort
    if (params['sortBy'] == 'createdAt' && params['sortAs'] == 'desc') {
      params.remove('sortBy');
      params.remove('sortAs');
    }

    return params.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Future<void> searchProducts({bool loadMore = false}) async {
    if (isSearchLoading.value) return;

    if (!loadMore) {
      offset = 0;
      searchResults.clear();
    }

    isSearchLoading.value = true;
    try {
      final queryParams = buildQueryParams();
      final newResults = await FilterService.to.searchPosts(queryParams);

      if (newResults.isNotEmpty) {
        searchResults.addAll(newResults);
        offset += limit;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSearchLoading.value = false;
    }
  }

  Map<String, String> _parseSortOption(String option) {
    final parts = option.split('_');
    return {
      'sortBy': parts.isNotEmpty ? parts[0] : 'createdAt',
      'sortAs': parts.length > 1 ? parts[1] : 'desc'
    };
  }

  // Delegation to BrandModelService
  void filterBrands(String query) => _brandModelSvc.brandSearchQuery.value = query;
  void filterModels(String query) => _brandModelSvc.modelSearchQuery.value = query;
  List<BrandDto> get filteredBrands => _brandModelSvc.filteredBrands;
  List<ModelDto> get filteredModels => _brandModelSvc.filteredModels;

  Future<void> fetchBrands() => _brandModelSvc.fetchBrands();
  Future<void> fetchModels(String brandUuid) => _brandModelSvc.fetchModels(brandUuid);

  void selectFilter(String val) {
    condition.value = val;
    debouncedSearch();
  }

  void selectLocation(String val) {
    selectedCountry.value = val;
    debouncedSearch();
  }

  void selectCategory(String uuid, String name) {
    selectedCategoryUuid.value = uuid;
    selectedCategoryName.value = name;
    debouncedSearch();
  }

  void selectColor(String color) {
    selectedColor.value = color;
    debouncedSearch();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
