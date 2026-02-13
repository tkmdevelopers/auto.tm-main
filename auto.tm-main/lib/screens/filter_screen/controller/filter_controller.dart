import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:auto_tm/domain/models/brand.dart';
import 'package:auto_tm/domain/models/car_model.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/post_filter.dart';
import 'package:auto_tm/domain/repositories/filter_repository.dart';
import 'package:auto_tm/domain/repositories/brand_repository.dart';
import 'package:auto_tm/screens/filter_screen/controller/brand_controller.dart';

class FilterController extends GetxController {
  final FilterRepository _filterRepository;
  final BrandRepository _brandRepository;
  final _storage = GetStorage();
  
  static const String _storageKey = 'persisted_filters_v1';
  
  final TextEditingController milleageController = TextEditingController();
  final TextEditingController enginepowerController = TextEditingController();
  final TextEditingController brandSearchController = TextEditingController();
  final TextEditingController modelSearchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  var offset = 0;
  final int limit = 20;
  // Tracks whether user has already opened the results page in this session.
  final RxBool hasViewedResults = false.obs;

  // Debounce timer for auto-search
  Timer? _debounce;
  void debouncedSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      saveFilterState();
      fetchMatchCount();
      
      // Auto-update history if a brand is selected to capture refinements (e.g. Region change)
      if (selectedBrandUuids.isNotEmpty) {
        try {
          final brandController = Get.find<BrandController>();
          brandController.addToHistory(
            brandUuid: selectedBrandUuids.first,
            brandName: selectedBrandNames.first,
            modelUuid: selectedModelUuids.isNotEmpty ? selectedModelUuids.first : null,
            modelName: selectedModelNames.isNotEmpty ? selectedModelNames.first : null,
            filterState: captureFilterState(),
          );
        } catch (_) {}
      }

      // If we are currently viewing results, also update the list
      if (hasViewedResults.value) {
        searchProducts();
      }
    });
  }

  FilterController({
    BrandRepository? brandRepository,
    FilterRepository? filterRepository,
  }) : _brandRepository = brandRepository ?? Get.find<BrandRepository>(),
       _filterRepository = filterRepository ?? Get.find<FilterRepository>();

  RxList<Brand> get brands => _brandRepository.brands;
  RxList<CarModel> get models => _brandRepository.models;
  RxBool get isLoadingBrands => _brandRepository.isLoadingBrands;
  RxBool get isLoadingModels => _brandRepository.isLoadingModels;
  final RxBool isLoading = false.obs;

  // Selection state (Support multi-selection)
  final RxSet<String> selectedBrandUuids = <String>{}.obs;
  final RxSet<String> selectedModelUuids = <String>{}.obs;
  final RxSet<String> selectedBrandNames = <String>{}.obs;
  final RxSet<String> selectedModelNames = <String>{}.obs;

  // Legacy accessors for compatibility
  String get selectedBrandUuid => selectedBrandUuids.isNotEmpty ? selectedBrandUuids.first : '';
  String get selectedModelUuid => selectedModelUuids.isNotEmpty ? selectedModelUuids.first : '';
  String get selectedBrandName => selectedBrandNames.isNotEmpty ? selectedBrandNames.join(', ') : '';
  String get selectedModelName => selectedModelNames.isNotEmpty ? selectedModelNames.join(', ') : '';

  final RxString selectedCategoryUuid = ''.obs;
  final RxString selectedCategoryName = ''.obs;

  // Filter state
  var selectedCountry = 'Local'.obs;
  var condition = 'All'.obs;
  var location = ''.obs; // Specific city
  var transmission = ''.obs;
  final RxSet<String> selectedColors = <String>{}.obs;
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
  final Rx<RangeValues> yearRange = Rx<RangeValues>(RangeValues(
    1990,
    DateTime.now().year.toDouble(),
  ));
  final RxInt priceLowerBound = 0.obs;
  final RxInt priceUpperBound = 1000000.obs;
  final Rx<RangeValues> priceRange = Rx<RangeValues>(const RangeValues(0, 1000000));

  // Year range accessors
  String get effectiveMinYear => minYear.value.isNotEmpty
      ? minYear.value
      : (yearRange.value.start != yearLowerBound.value
            ? yearRange.value.start.round().toString()
            : '');
  String get effectiveMaxYear => maxYear.value.isNotEmpty
      ? maxYear.value
      : (yearRange.value.end != yearUpperBound.value
            ? yearRange.value.end.round().toString()
            : '');

  final RxString selectedSortOption = 'createdAt_desc'.obs;
  final RxBool isSearchLoading = false.obs;
  final RxBool isCountLoading = false.obs;
  final RxInt totalMatches = 0.obs;
  final RxList<Post> searchResults = <Post>[].obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPersistedFilters();

    // Sync isLoading with service states
    ever(
      isLoadingBrands,
      (val) => isLoading.value = val || isLoadingModels.value,
    );
    ever(
      isLoadingModels,
      (val) => isLoading.value = val || isLoadingBrands.value,
    );

    // Listen to text controllers for auto-search
    milleageController.addListener(debouncedSearch);
    enginepowerController.addListener(debouncedSearch);

    // Unified listener for all filter changes
    final List<RxInterface> filters = [
      transmission,
      condition,
      exchange,
      credit,
      minYear,
      maxYear,
      minPrice,
      maxPrice,
      priceRange,
      yearRange,
      selectedBrandUuids,
      selectedModelUuids,
      selectedCategoryUuid,
      selectedColors,
      location,
      selectedCountry,
    ];

    for (var filter in filters) {
      ever(filter, (_) => debouncedSearch());
    }

    // Initial fetch
    fetchMatchCount();
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
    selectedColors.clear();
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
      selectedBrandUuids.clear();
      selectedModelUuids.clear();
      selectedBrandNames.clear();
      selectedModelNames.clear();
      selectedCategoryUuid.value = '';
      selectedCategoryName.value = '';
    }
    saveFilterState();
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
    if (selectedBrandUuids.isNotEmpty) count++;
    if (selectedModelUuids.isNotEmpty) count++;
    if (selectedCategoryUuid.value.isNotEmpty) count++;
    if (selectedCountry.value != 'Local' || location.value.isNotEmpty) count++;
    if (transmission.value.isNotEmpty) count++;
    if (credit.value) count++;
    if (exchange.value) count++;
    if (minYear.value.isNotEmpty || maxYear.value.isNotEmpty) count++;
    if (milleageController.text.isNotEmpty) count++;
    if (enginepowerController.text.isNotEmpty) count++;
    if (selectedColors.isNotEmpty) count++;
    if (premium.isNotEmpty) count++;
    if (condition.value.isNotEmpty && condition.value != 'All') count++;
    return count;
  }

  PostFilter buildFilter({bool countOnly = false}) {
    final sort = _parseSortOption(selectedSortOption.value);

    return PostFilter(
      brandFilter: selectedBrandUuids.isNotEmpty
          ? selectedBrandUuids.toList()
          : null,
      modelFilter: selectedModelUuids.isNotEmpty
          ? selectedModelUuids.toList()
          : null,
      categoryFilter: selectedCategoryUuid.value.isNotEmpty
          ? selectedCategoryUuid.value
          : null,
      region: selectedCountry.value != 'Local' ? selectedCountry.value : null,
      location: (selectedCountry.value == 'Local' && location.value.isNotEmpty)
          ? location.value
          : null,
      color: selectedColors.isNotEmpty ? selectedColors.toList() : null,
      credit: credit.value ? true : null,
      exchange: exchange.value ? true : null,
      transmission: transmission.value.isNotEmpty ? transmission.value : null,
      enginePower: enginepowerController.text.isNotEmpty
          ? enginepowerController.text
          : null,
      milleage: milleageController.text.isNotEmpty
          ? milleageController.text
          : null,
      condition: condition.value != 'All' ? condition.value : null,
      minYear: minYear.value.isNotEmpty
          ? minYear.value
          : (yearRange.value.start != yearLowerBound.value
                ? yearRange.value.start.round().toString()
                : null),
      maxYear: maxYear.value.isNotEmpty
          ? maxYear.value
          : (yearRange.value.end != yearUpperBound.value
                ? yearRange.value.end.round().toString()
                : null),
      minPrice: minPrice.value != null
          ? minPrice.value.toString()
          : (priceRange.value.start != priceLowerBound.value
                ? priceRange.value.start.round().toString()
                : null),
      maxPrice: maxPrice.value != null
          ? maxPrice.value.toString()
          : (priceRange.value.end != priceUpperBound.value
                ? priceRange.value.end.round().toString()
                : null),
      subFilter: premium.isNotEmpty ? premium.toList() : null,
      sortBy: sort['sortBy'],
      sortAs: sort['sortAs'],
      countOnly: countOnly ? true : null,
    );
  }

  Future<void> fetchMatchCount() async {
    isCountLoading.value = true;
    try {
      final filter = buildFilter(countOnly: true);
      totalMatches.value = await _filterRepository.getMatchCount(filter);
    } catch (e) {
      print('Error fetching match count: $e');
    } finally {
      isCountLoading.value = false;
    }
  }

  Future<void> searchProducts({bool loadMore = false}) async {
    if (isSearchLoading.value) return;

    if (!loadMore) {
      offset = 0;
      searchResults.clear();
    }

    isSearchLoading.value = true;
    try {
      final filter = buildFilter();
      final result = await _filterRepository.searchPosts(
        offset: offset,
        limit: limit,
        filters: filter,
      );

      if (result.posts.isNotEmpty) {
        searchResults.addAll(result.posts);
        offset += limit;
      }
      totalMatches.value = result.totalCount;
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
      'sortAs': parts.length > 1 ? parts[1] : 'desc',
    };
  }

  // Delegation to BrandRepository
  void filterBrands(String query) =>
      _brandRepository.brandSearchQuery.value = query;
  void filterModels(String query) =>
      _brandRepository.modelSearchQuery.value = query;
  List<Brand> get filteredBrands => _brandRepository.filteredBrands;
  List<CarModel> get filteredModels => _brandRepository.filteredModels;

  Future<void> fetchBrands() => _brandRepository.fetchBrands();
  Future<void> fetchModels(String brandUuid) =>
      _brandRepository.fetchModels(brandUuid);

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

  // Multi-selection methods
  void toggleBrand(String uuid, String name) {
    if (selectedBrandUuids.contains(uuid)) {
      selectedBrandUuids.remove(uuid);
      selectedBrandNames.remove(name);
      // Clear models if brand removed? (Maybe not if multiple brands)
    } else {
      selectedBrandUuids.add(uuid);
      selectedBrandNames.add(name);
      fetchModels(uuid);
    }
  }

  void toggleModel(String uuid, String name) {
    if (selectedModelUuids.contains(uuid)) {
      selectedModelUuids.remove(uuid);
      selectedModelNames.remove(name);
    } else {
      selectedModelUuids.add(uuid);
      selectedModelNames.add(name);
    }
  }

  void toggleColor(String color) {
    if (selectedColors.contains(color)) {
      selectedColors.remove(color);
    } else {
      selectedColors.add(color);
    }
  }

  // Legacy selection methods (updated for compatibility)
  void selectBrand(String uuid, String name) {
    selectedBrandUuids.clear();
    selectedBrandNames.clear();
    selectedBrandUuids.add(uuid);
    selectedBrandNames.add(name);
    selectedModelUuids.clear();
    selectedModelNames.clear();
    fetchModels(uuid);
  }

  void selectModel(String uuid, String name) {
    selectedModelUuids.clear();
    selectedModelNames.clear();
    selectedModelUuids.add(uuid);
    selectedModelNames.add(name);
  }

  void selectColor(String color) {
    selectedColors.clear();
    selectedColors.add(color);
  }

  Map<String, dynamic> captureFilterState() {
    return {
      'transmission': transmission.value,
      'condition': condition.value,
      'exchange': exchange.value,
      'credit': credit.value,
      'minYear': minYear.value,
      'maxYear': maxYear.value,
      'minPrice': minPrice.value,
      'maxPrice': maxPrice.value,
      'yearRangeStart': yearRange.value.start,
      'yearRangeEnd': yearRange.value.end,
      'priceRangeStart': priceRange.value.start,
      'priceRangeEnd': priceRange.value.end,
      'selectedCategoryUuid': selectedCategoryUuid.value,
      'selectedCategoryName': selectedCategoryName.value,
      'selectedColors': selectedColors.toList(),
      'location': location.value,
      'selectedCountry': selectedCountry.value,
      'milleage': milleageController.text,
      'enginePower': enginepowerController.text,
    };
  }

  void restoreFilterState(Map<String, dynamic> state) {
    transmission.value = state['transmission'] ?? '';
    condition.value = state['condition'] ?? 'All';
    exchange.value = state['exchange'] ?? false;
    credit.value = state['credit'] ?? false;
    minYear.value = state['minYear'] ?? '';
    maxYear.value = state['maxYear'] ?? '';
    minPrice.value = state['minPrice'];
    maxPrice.value = state['maxPrice'];
    
    if (state['yearRangeStart'] != null && state['yearRangeEnd'] != null) {
      yearRange.value = RangeValues(
        (state['yearRangeStart'] as num).toDouble(),
        (state['yearRangeEnd'] as num).toDouble(),
      );
    }
    
    if (state['priceRangeStart'] != null && state['priceRangeEnd'] != null) {
      priceRange.value = RangeValues(
        (state['priceRangeStart'] as num).toDouble(),
        (state['priceRangeEnd'] as num).toDouble(),
      );
    }

    selectedCategoryUuid.value = state['selectedCategoryUuid'] ?? '';
    selectedCategoryName.value = state['selectedCategoryName'] ?? '';
    
    if (state['selectedColors'] != null) {
      selectedColors.assignAll(List<String>.from(state['selectedColors']));
    }
    
    location.value = state['location'] ?? '';
    selectedCountry.value = state['selectedCountry'] ?? 'Local';
    milleageController.text = state['milleage'] ?? '';
    enginepowerController.text = state['enginePower'] ?? '';
    
    saveFilterState(); // Persist the restored state
  }

  void saveFilterState() {
    final state = {
      ...captureFilterState(),
      'selectedBrandUuids': selectedBrandUuids.toList(),
      'selectedModelUuids': selectedModelUuids.toList(),
      'selectedBrandNames': selectedBrandNames.toList(),
      'selectedModelNames': selectedModelNames.toList(),
    };
    _storage.write(_storageKey, state);
  }

  void _loadPersistedFilters() {
    final state = _storage.read(_storageKey);
    if (state != null && state is Map) {
      final mapState = Map<String, dynamic>.from(state);
      restoreFilterState(mapState);

      if (mapState['selectedBrandUuids'] != null) {
        selectedBrandUuids.assignAll(List<String>.from(mapState['selectedBrandUuids']));
      }
      if (mapState['selectedModelUuids'] != null) {
        selectedModelUuids.assignAll(List<String>.from(mapState['selectedModelUuids']));
      }
      if (mapState['selectedBrandNames'] != null) {
        selectedBrandNames.assignAll(List<String>.from(mapState['selectedBrandNames']));
      }
      if (mapState['selectedModelNames'] != null) {
        selectedModelNames.assignAll(List<String>.from(mapState['selectedModelNames']));
      }
      
      if (selectedBrandUuids.isNotEmpty) {
        fetchModels(selectedBrandUuids.first);
      }
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    milleageController.dispose();
    enginepowerController.dispose();
    brandSearchController.dispose();
    modelSearchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
