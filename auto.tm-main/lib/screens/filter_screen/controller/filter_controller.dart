import 'dart:convert';
import 'dart:isolate';

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class FilterController extends GetxController {
  final TextEditingController milleageController = TextEditingController();
  final TextEditingController enginepowerController = TextEditingController();
  final TextEditingController brandSearchController = TextEditingController();
  final TextEditingController modelSearchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final box = GetStorage();
  var offset = 0;
  final int limit = 20;

  var selectedCountry = 'Local'.obs;
  var condition = 'All'.obs;
  var brands = <Map<String, dynamic>>[].obs;
  var models = <Map<String, dynamic>>[].obs;
  var selectedBrand = ''.obs;
  var selectedModel = ''.obs;
  var selectedBrandUuid = ''.obs;
  var selectedModelUuid = ''.obs;
  var location = 'Ashgabat'.obs;
  var transmission = ''.obs;
  var enginePower = ''.obs;
  var selectedColor = ''.obs;
  final selectedMinDate = DateTime.now().obs;
  final selectedMaxDate = DateTime.now().obs;

  var milleage = ''.obs;
  var isLoading = false.obs;
  var exchange = false.obs;
  var credit = false.obs;
  var premium = <String>[].obs;

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

  @override
  void onClose() {
    milleageController.dispose();
    enginepowerController.dispose();
    brandSearchController.dispose();
    modelSearchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

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
                selectedMinDate.value = dateTime;
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
                selectedMaxDate.value = dateTime;
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
  }

  final isSearchLoading = false.obs;
  final searchResults = <Post>[].obs;

  void filterBrands(String query) {
    if (brandSearchController.text.isEmpty) {
      filteredBrands.assignAll(brands);
    } else {
      filteredBrands.assignAll(
        brands
            .where(
              (brand) => brand['name'].toString().toLowerCase().contains(
                brandSearchController.text.toLowerCase(),
              ),
            )
            .toList(),
      );
    }
  }

  void filterModels(String query) {
    if (modelSearchController.text.isEmpty) {
      filteredModels.assignAll(models);
    } else {
      filteredModels.assignAll(
        models
            .where(
              (model) => model['name'].toString().toLowerCase().contains(
                modelSearchController.text.toLowerCase(),
              ),
            )
            .toList(),
      );
    }
  }

  String buildQuery() {
    Map<String, String> queryParams = {};

    if (selectedBrandUuid.value.isNotEmpty) {
      queryParams['brandFilter'] = selectedBrandUuid.value;
    }
    if (selectedCountry.value == 'Local') {
      if (location.value.isNotEmpty) {
        queryParams['location'] = location.value;
      }
    } else {
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
    if (selectedMinYear != '' && selectedMaxYear != '') {
      int minYear = int.tryParse(selectedMinYear) ?? 0;
      int maxYear = int.tryParse(selectedMaxYear) ?? 0;

      // Swap if min is greater than max
      if (minYear > maxYear) {
        final temp = minYear;
        minYear = maxYear;
        maxYear = temp;
      }

      queryParams['minYear'] = minYear.toString();
      queryParams['maxYear'] = maxYear.toString();
    } else {
      if (selectedMinYear != '') {
        queryParams['minYear'] = selectedMinYear;
      }
      if (selectedMaxYear != '') {
        queryParams['maxYear'] = selectedMaxYear;
      }
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
      final response = await http.get(
        Uri.parse(searchApiUrl),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
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
      } else if (response.statusCode == 406) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return searchProducts(loadMore: loadMore);
        } else {
          Get.snackbar('Error', 'Login expired. Please log in again.');
        }
      } else {
        if (!loadMore) searchResults.clear();
      }
    } catch (e) {
      if (!loadMore) searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  final lastSubscribes = <String>[].obs;

  void saveSubscribes() {
    box.write('brand_subscribes', lastSubscribes.toList());
  }

  Future<void> loadStoredSubscribes() async {
    List<String>? storedHistory = box
        .read<List>('brand_subscribes')
        ?.cast<String>();
    if (storedHistory != null) {
      lastSubscribes.assignAll(storedHistory);
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

      final response = await http.post(
        Uri.parse(ApiKey.subscribeToBrandKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
        },
        body: json.encode(requestdata),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        addToSubscribes(selectedBrandUuid.value);
      }
      if (response.statusCode == 406) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return subscribeToBrand();
        } else {
          Get.snackbar(
            'Error',
            'Failed to refresh access token. Please log in again.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
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

      final response = await http.post(
        Uri.parse(ApiKey.unsubscribeToBrandKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
        },
        body: json.encode(requestdata),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        removeFromSubscribes(selectedBrandUuid.value);
      }
      if (response.statusCode == 406) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return unSubscribeFromBrand();
        } else {
          Get.snackbar(
            'Error',
            'Failed to refresh access token. Please log in again.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      isSearchLoading.value = false;
    }
  }

  void selectFilter(String filter) {
    condition.value = filter;
  }

  void selectLocation(String filter) {
    selectedCountry.value = filter;
  }

  void fetchBrands() async {
    isLoadingBrands.value = true;
    try {
      final response = await http
          .get(
            Uri.parse(ApiKey.getBrandsKey),
            headers: {
              "Content-Type": "application/json",
              'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
            },
          )
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        brands.value = List<Map<String, dynamic>>.from(decodedData);
        filteredBrands.value = List<Map<String, dynamic>>.from(decodedData);
      }
      if (response.statusCode == 406) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return fetchBrands();
        } else {
          Get.snackbar(
            'Error',
            'Failed to refresh access token. Please log in again.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      isLoadingBrands.value = false;
    }
  }

  void fetchModels(String brand) async {
    isLoadingModels.value = true;
    try {
      final response = await http
          .get(
            Uri.parse("${ApiKey.getModelsKey}?filter=$brand"),
            headers: {
              "Content-Type": "application/json",
              'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
            },
          )
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        models.value = List<Map<String, dynamic>>.from(decodedData);
        filteredModels.value = List<Map<String, dynamic>>.from(decodedData);
      }
      if (response.statusCode == 406) {
        await refreshAccessToken();
      }
    } catch (e) {
      // Handle error silently
    } finally {
      isLoadingModels.value = false;
    }
  }

  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = box.read('REFRESH_TOKEN');

      final response = await http.get(
        Uri.parse(ApiKey.refreshTokenKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        if (newAccessToken != null) {
          box.remove('ACCESS_TOKEN');
          box.write('ACCESS_TOKEN', newAccessToken);
          return true;
        } else {
          return false;
        }
      }
      if (response.statusCode == 406) {
        Get.offAllNamed('/login');
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
