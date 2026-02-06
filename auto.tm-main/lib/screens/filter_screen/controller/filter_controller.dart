import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

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

  // Country selection (defaults to 'Local')
  var selectedCountry = 'Local'.obs;
  var condition = 'All'.obs;
  var brands = <Map<String, dynamic>>[].obs;
  var models = <Map<String, dynamic>>[].obs;
  var selectedBrand = ''.obs;
  var selectedModel = ''.obs;
  var selectedBrandUuid = ''.obs;
  var selectedModelUuid = ''.obs;
  // Specific location city (blank means any)
  var location = ''.obs;
  var transmission = ''.obs;
  var enginePower = ''.obs;
  var selectedColor = ''.obs;
  // Year filters (allow empty). Using strings so they can be blank until user selects.
  final RxString minYear = ''.obs;
  final RxString maxYear = ''.obs;
  // Slider bounds (will initialize lazily from data or defaults)
  final RxInt yearLowerBound = 1990.obs;
  final RxInt yearUpperBound = DateTime.now().year.obs;
  final Rx<RangeValues> yearRange = RangeValues(
    1990,
    DateTime.now().year.toDouble(),
  ).obs;
  // Legacy date objects kept temporarily for compatibility; will be removed once UI updated.
  final selectedMinDate = DateTime.now().obs; // TODO: remove
  final selectedMaxDate = DateTime.now().obs; // TODO: remove

  var milleage = ''.obs;
  var isLoading = false.obs;
  var exchange = false.obs;
  var credit = false.obs;
  var premium = <String>[].obs;
  // Price range (nullable). We'll treat empty as not set.
  final RxnInt minPrice = RxnInt();
  final RxnInt maxPrice = RxnInt();
  // Optional UI bounds for price slider if later added
  final RxInt priceLowerBound = 0.obs;
  final RxInt priceUpperBound = 500000.obs; // adjust after meta fetch
  final Rx<RangeValues> priceRange = const RangeValues(0, 500000).obs;

  RxBool isLoadingBrands = false.obs;
  RxBool isLoadingModels = false.obs;
  RxString error = ''.obs;

  RxList<Map<String, dynamic>> filteredBrands = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredModels = <Map<String, dynamic>>[].obs;

  final RxString selectedSortOption = 'createdAt_desc'.obs;

  @override
  void onInit() {
    super.onInit();

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

  // Removed onClose disposal to avoid disposing controllers for a permanent instance.

  void updateSortOption(String newSortOption) {
    if (selectedSortOption.value != newSortOption) {
      selectedSortOption.value = newSortOption;
      searchProducts(); // Перезагружаем посты с новой сортировкой
    }
  }

  void showDatePickerAndroidMin(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select year".tr),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1900, 1),
              lastDate: DateTime(DateTime.now().year, 1),
              initialDate: DateTime.now(),
              selectedDate: selectedMinDate.value,
              onChanged: (DateTime dateTime) {
                selectedMinDate.value = dateTime; // legacy
                minYear.value = dateTime.year.toString();
                NavigationUtils.closeGlobal();
              },
            ),
          ),
        );
      },
    );
  }

  void showDatePickerAndroidMax(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select year".tr),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1900, 1),
              lastDate: DateTime(DateTime.now().year, 1),
              initialDate: DateTime.now(),
              selectedDate: selectedMaxDate.value,
              onChanged: (DateTime dateTime) {
                selectedMaxDate.value = dateTime; // legacy
                maxYear.value = dateTime.year.toString();
                NavigationUtils.closeGlobal();
              },
            ),
          ),
        );
      },
    );
  }

  String get selectedMinYear => "${selectedMinDate.value.year}";
  String get selectedMaxYear => "${selectedMaxDate.value.year}";
  // Accessors for new year state (prefer these going forward)
  String get effectiveMinYear => minYear.value.isNotEmpty ? minYear.value : '';
  String get effectiveMaxYear => maxYear.value.isNotEmpty ? maxYear.value : '';

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
    if (includeBrandModel) {
      selectedBrand.value = '';
      selectedBrandUuid.value = '';
      selectedModel.value = '';
      selectedModelUuid.value = '';
    }
  }

  Map<String, String> _parseSortOption(String option) {
    if (option.contains('_')) {
      final parts = option.split('_');
      return {'sortBy': parts[0], 'sortAs': parts[1]};
    }
    return {'sortBy': option, 'sortAs': 'desc'};
  }

  void togglePremium(String uuid) {
    if (premium.contains(uuid)) {
      premium.remove(uuid);
    } else {
      premium.add(uuid);
    }
    debouncedSearch();
  }

  final isSearchLoading = false.obs;
  final searchResults = <Post>[].obs;

  // Computed active filter count for UI chips & summary bar
  int get activeFilterCount {
    int count = 0;
    if (selectedBrandUuid.value.isNotEmpty) count++;
    if (selectedModelUuid.value.isNotEmpty) count++;
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

  void filterBrands(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredBrands.assignAll(brands);
      return;
    }
    filteredBrands.assignAll(
      brands
          .where((brand) => brand['name'].toString().toLowerCase().contains(q))
          .toList(),
    );
  }

  void filterModels(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredModels.assignAll(models);
      return;
    }
    filteredModels.assignAll(
      models
          .where((model) => model['name'].toString().toLowerCase().contains(q))
          .toList(),
    );
  }

  String buildQuery() {
    Map<String, String> queryParams = {};

    if (selectedBrandUuid.value.isNotEmpty) {
      queryParams['brandFilter'] = selectedBrandUuid.value;
    }
    // Location / country logic: 'Local' means use city (if chosen) but do not send 'Local' as value
    if (selectedCountry.value == 'Local') {
      if (location.value.isNotEmpty) {
        queryParams['location'] = location.value;
      }
    } else if (selectedCountry.value.isNotEmpty) {
      queryParams['location'] = selectedCountry.value;
    }
    if (selectedModelUuid.value.isNotEmpty) {
      queryParams['modelFilter'] = selectedModelUuid.value;
    }
    if (selectedColor.value.isNotEmpty) {
      queryParams['color'] = selectedColor.value;
    }
    if (credit.value) queryParams['credit'] = credit.value.toString();
    if (exchange.value) queryParams['exchange'] = exchange.value.toString();
    if (transmission.value.isNotEmpty) {
      queryParams['transmission'] = transmission.value;
    }
    if (enginepowerController.text.isNotEmpty) {
      queryParams['enginePower'] = enginepowerController.text;
    }
    if (milleageController.text != '') {
      queryParams['milleage'] = milleageController.text;
    }
    if (condition.value.isNotEmpty && condition.value != 'All') {
      queryParams['condition'] = condition.value;
    }
    // Year filters (use new minYear/maxYear; include only if set)
    // Consolidate year logic: prefer explicit text fields if set, else fall back to slider values when moved from defaults
    if (minYear.value.isNotEmpty || maxYear.value.isNotEmpty) {
      if (minYear.value.isNotEmpty) queryParams['minYear'] = minYear.value;
      if (maxYear.value.isNotEmpty) queryParams['maxYear'] = maxYear.value;
    } else {
      final rv = yearRange.value;
      final defaultMin = yearLowerBound.value.toDouble();
      final defaultMax = yearUpperBound.value.toDouble();
      if (rv.start != defaultMin)
        queryParams['minYear'] = rv.start.round().toString();
      if (rv.end != defaultMax)
        queryParams['maxYear'] = rv.end.round().toString();
    }

    // Price logic: explicit minPrice/maxPrice if set, else slider delta from defaults
    if (minPrice.value != null || maxPrice.value != null) {
      if (minPrice.value != null)
        queryParams['minPrice'] = minPrice.value.toString();
      if (maxPrice.value != null)
        queryParams['maxPrice'] = maxPrice.value.toString();
    } else {
      final pr = priceRange.value;
      final dMin = priceLowerBound.value.toDouble();
      final dMax = priceUpperBound.value.toDouble();
      if (pr.start != dMin)
        queryParams['minPrice'] = pr.start.round().toString();
      if (pr.end != dMax) queryParams['maxPrice'] = pr.end.round().toString();
    }

    return queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> searchProducts({bool loadMore = false}) async {
    if (!loadMore) {
      offset = 0;
      searchResults.clear();
    }

    String queryString = buildQuery();
    String queryStringPremium = '';
    if (premium.isNotEmpty) {
      for (int i = 0; i < premium.length; i++) {
        final id = premium[i];
        queryStringPremium += 'subFilter=$id';
        if (i < premium.length - 1) {
          queryStringPremium += '&';
        }
      }
    }

    final parsedOptions = _parseSortOption(selectedSortOption.value);
    final String sortBy = parsedOptions['sortBy']!;
    final String sortAs = parsedOptions['sortAs']!;
    final String searchApiUrl =
        '${ApiKey.searchPostsKey}?&brand=true&model=true&photo=true&subscription=true&$queryString&status=true&sortAs=$sortAs&sortBy=$sortBy&$queryStringPremium&offset=$offset&limit=$limit';

    isSearchLoading.value = true;
    try {
      final accessToken = await TokenStore.to.accessToken;
      final response = await http.get(
        Uri.parse(searchApiUrl),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<Post> newResults = await Isolate.run(() {
          final List<dynamic> data = json.decode(response.body);
          return data.map((item) => Post.fromJson(item)).toList();
        });

        if (newResults.isNotEmpty) {
          searchResults.addAll(newResults);
          offset += limit;
        }

        _applyRegionAndCityFilters();
      } else if (response.statusCode == 401) {
        Get.snackbar('Error', 'Login expired. Please log in again.');
      } else {
        if (!loadMore) searchResults.clear();
      }
    } catch (e) {
      if (!loadMore) searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  void _applyRegionAndCityFilters() {
    final regionFilterRaw = selectedCountry.value.trim();
    if (regionFilterRaw.isEmpty) return; // nothing to filter by
    final regionFilter = regionFilterRaw.toLowerCase();
    final cityFilter = location.value.trim().toLowerCase();

    // Build filtered list; treat posts with missing region as 'local'
    final filtered = <Post>[];
    for (final p in searchResults) {
      // Pull region from strongly typed field; fallback already handled in Post.fromJson
      var postRegion = p.region.trim();
      if (postRegion.isEmpty) {
        // Legacy posts before region introduction considered Local
        postRegion = 'Local';
      }
      final regionMatch = postRegion.toLowerCase() == regionFilter;
      if (!regionMatch) continue;

      if (regionFilter == 'local') {
        if (cityFilter.isEmpty) {
          // Any local city accepted when user didn't choose a city
          filtered.add(p);
        } else {
          final postCity = p.location.trim().toLowerCase();
          if (postCity.isNotEmpty && postCity == cityFilter) {
            filtered.add(p);
          }
        }
      } else {
        // Non-local regions ignore city list (UI already disabled city selection)
        filtered.add(p);
      }
    }
    searchResults.assignAll(filtered);
  }

  final lastSubscribes = <String>[].obs;

  void saveSubscribes() {
    box.write('brand_subscribes', lastSubscribes.toList());
  }

  Future<void> loadStoredSubscribes() async {
    final stored = box.read<List>('brand_subscribes');
    if (stored != null) {
      lastSubscribes.assignAll(stored.cast<String>());
    }
  }

  void addToSubscribes(String uuid) {
    if (!lastSubscribes.contains(uuid)) {
      lastSubscribes.add(uuid);
    }
    saveSubscribes();
  }

  void removeFromSubscribes(String uuid) {
    if (lastSubscribes.contains(uuid)) {
      lastSubscribes.remove(uuid);
    }
    saveSubscribes();
  }

  void subscribeToBrand() async {
    try {
      final Map<String, dynamic> requestdata = {
        'uuid': selectedBrandUuid.value,
      };

      final accessToken = await TokenStore.to.accessToken;
      final response = await http.post(
        Uri.parse(ApiKey.subscribeToBrandKey),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(requestdata),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        addToSubscribes(selectedBrandUuid.value);
      }
      // Auth errors are handled by ApiClient interceptor for Dio calls.
    } catch (e) {
      // Handle error silently
    } finally {
      isSearchLoading.value = false;
    }
  }

  void unSubscribeFromBrand() async {
    try {
      final Map<String, dynamic> requestdata = {
        'uuid': selectedBrandUuid.value,
      };

      final accessToken = await TokenStore.to.accessToken;
      final response = await http.post(
        Uri.parse(ApiKey.unsubscribeToBrandKey),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(requestdata),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        removeFromSubscribes(selectedBrandUuid.value);
      }
      // Auth errors are handled by ApiClient interceptor for Dio calls.
    } catch (e) {
      // Handle error silently
    } finally {
      isSearchLoading.value = false;
    }
  }

  void selectFilter(String filter) {
    condition.value = filter;
    debouncedSearch();
  }

  void selectLocation(String filter) {
    selectedCountry.value = filter;
    debouncedSearch();
  }

  void fetchBrands() async {
    isLoadingBrands.value = true;
    try {
      final accessToken = await TokenStore.to.accessToken;
      final response = await http
          .get(
            Uri.parse(ApiKey.getBrandsKey),
            headers: {
              "Content-Type": "application/json",
              if (accessToken != null && accessToken.isNotEmpty)
                'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        brands.value = List<Map<String, dynamic>>.from(decodedData);
        filteredBrands.value = List<Map<String, dynamic>>.from(decodedData);
      }
      // Auth errors are handled by ApiClient interceptor for Dio calls.
    } catch (e) {
      // Handle error silently
    } finally {
      isLoadingBrands.value = false;
    }
  }

  void fetchModels(String brand) async {
    isLoadingModels.value = true;
    try {
      final accessToken = await TokenStore.to.accessToken;
      final response = await http
          .get(
            Uri.parse("${ApiKey.getModelsKey}?filter=$brand"),
            headers: {
              "Content-Type": "application/json",
              if (accessToken != null && accessToken.isNotEmpty)
                'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        models.value = List<Map<String, dynamic>>.from(decodedData);
        filteredModels.value = List<Map<String, dynamic>>.from(decodedData);
      }
      // Auth errors are handled by ApiClient interceptor for Dio calls.
    } catch (e) {
      // Handle error silently
    } finally {
      isLoadingModels.value = false;
    }
  }

  // Token refresh is now handled by the Dio ApiClient interceptor.
  // The duplicated refreshAccessToken() method has been removed.
  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
