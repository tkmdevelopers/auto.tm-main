import 'dart:convert';
import 'dart:async';
import 'dart:isolate';

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FavoritesController extends GetxController {
  final box = GetStorage();
  final isFavorite = false.obs;
  final favoriteProducts = <Post>[].obs;
  final favorites = <String>[].obs;
  final RxBool showPosts = true.obs;

  final RxBool isLoadingPosts = false.obs;
  final RxBool isLoadingSubscribedBrands = false.obs;
  final RxBool isRefreshingToken = false.obs;
  final lastSubscribes = <String>[].obs;
  final RxList<Map<String, dynamic>> subscribedBrands =
      <Map<String, dynamic>>[].obs;
  final RxList<Post> subscribeBrandPosts = <Post>[].obs;

  // Debounce timer for batching rapid favorite toggles before fetching details
  Timer? _favoritesDebounce;

  List<String> loadFavorites() {
    return box.read<List<String>>('favorites') ?? [];
  }

  void toggleTab(bool isPostTabSelected) {
    showPosts.value = isPostTabSelected;
    if (!isPostTabSelected) {
      // fetchSubscribedBrands();
      fetchBrandSubscribes();
    } else {
      fetchFavoriteProducts();
    }
  }

  Future<void> handleBrandSubscriptionToggle(
    String brandUuid,
    bool newValue,
  ) async {
    if (newValue) {
      await subscribeToBrand(brandUuid);
    } else {
      await unSubscribeFromBrand(brandUuid);
    }
  }

  Future<void> loadStoredFavorites() async {
    List<String>? storedFavorites = box.read<List>('favorites')?.cast<String>();
    if (storedFavorites != null) {
      favorites.assignAll(storedFavorites);
    }
  }

  // Save Favorites to GetStorage
  void saveFavorites() {
    box.write('favorites', favorites.toList());
  }

  Future<void> fetchFavoriteProducts() async {
    if (favorites.isEmpty) {
      favoriteProducts.clear();
      return;
    }

    final url = Uri.parse(ApiKey.getFavoritesKey);
    try {
      final response = await http.post(
        url,
        headers: {
          // "Accept": "application/json",
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${await TokenStore.to.accessToken}',
        },
        body: json.encode({
          "uuids": favorites,
          "brand": "true",
          "model": "true",
          "photo": "true",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          favoriteProducts.assignAll(
            data.map((item) => Post.fromJson(item)).toList(),
          );
        }
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  void toggleFavorite(String uuid) {
    final removing = favorites.contains(uuid);
    if (removing) {
      // Optimistic UI update: remove immediately from both id list and product details list
      favorites.remove(uuid);
      favoriteProducts.removeWhere((p) => p.uuid == uuid);
      isFavorite.value = false;
    } else {
      favorites.add(uuid);
      isFavorite.value = true;
    }
    saveFavorites();
    _scheduleFavoritesSync(afterRemoval: removing);
  }

  void removeOne(String uuid) {
    if (favorites.remove(uuid)) {
      favoriteProducts.removeWhere((p) => p.uuid == uuid);
      isFavorite.value = false;
      saveFavorites();
      _scheduleFavoritesSync(afterRemoval: true);
    }
  }

  void removeAll() {
    if (favorites.isNotEmpty) {
      favorites.clear();
      favoriteProducts.clear();
      isFavorite.value = false;
      saveFavorites();
      _cancelFavoritesDebounce();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadStoredFavorites(); // Load saved favorites from GetStorage
    loadStoredSubscribes();
    // Initial data fetch (favorites + their details)
    refreshData();
  }

  Future<void> refreshData() async {
    await loadStoredFavorites();
    await fetchFavoriteProducts();
  }

  void _scheduleFavoritesSync({required bool afterRemoval}) {
    // If we removed and list is now empty, just clear details and skip fetch
    if (favorites.isEmpty) {
      favoriteProducts.clear();
      _cancelFavoritesDebounce();
      return;
    }
    // When adding, or removing but still have items, debounce the details fetch
    _favoritesDebounce?.cancel();
    _favoritesDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchFavoriteProducts();
    });
  }

  void _cancelFavoritesDebounce() {
    _favoritesDebounce?.cancel();
    _favoritesDebounce = null;
  }

  // Token refresh is now handled by the Dio ApiClient interceptor.
  // The duplicated refreshAccessToken() method has been removed.

  Future<void> subscribeToBrand(String brandUuid) async {
    try {
      final Map<String, dynamic> requestdata = {'uuid': brandUuid};

      final response = await http.post(
        Uri.parse(ApiKey.subscribeToBrandKey),
        headers: {
          // "Accept": "application/json",
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${await TokenStore.to.accessToken}',
        },
        body: json.encode(requestdata),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'common_success'.tr,
          'favourites_subscribe_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        addToSubscribes(brandUuid);
        fetchBrandSubscribes();
      }
      // Auth errors are handled by ApiClient interceptor for Dio calls.
    } catch (e) {
      // searchResults.clear();
    } finally {
      isLoadingSubscribedBrands.value = false;
    }
  }

  Future<void> unSubscribeFromBrand(String brandUuid) async {
    try {
      final Map<String, dynamic> requestdata = {'uuid': brandUuid};

      final response = await http.post(
        Uri.parse(ApiKey.unsubscribeToBrandKey),
        headers: {
          // "Accept": "application/json",
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${await TokenStore.to.accessToken}',
        },
        body: json.encode(requestdata),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'common_success'.tr,
          'favourites_unsubscribe_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        removeFromSubscribes(brandUuid);
        fetchBrandSubscribes(); // Обновляем список после удаления
      }
      // Auth errors are handled by ApiClient interceptor for Dio calls.
    } catch (e) {
      // searchResults.clear();
    } finally {
      isLoadingSubscribedBrands.value = false;
    }
  }

  String formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate); // Convert string to DateTime
    String formattedDate = DateFormat(
      'dd.MM.yyyy',
    ).format(dateTime); // Format to dd.MM.yyyy
    return formattedDate;
  }

  List<String> loadSubscribes() {
    return box.read<List<String>>('brand_subscribes') ?? [];
  }

  Future<void> loadStoredSubscribes() async {
    List<String>? storedHistory = box
        .read<List>('brand_subscribes')
        ?.cast<String>();
    if (storedHistory != null) {
      lastSubscribes.assignAll(storedHistory);
    }
  }

  void saveSubscribes() {
    box.write('brand_subscribes', lastSubscribes.toList());
  }

  Future<void> fetchBrandSubscribes() async {
    isLoadingSubscribedBrands.value = true;
    if (lastSubscribes.isEmpty) {
      subscribedBrands.clear();
      subscribeBrandPosts.clear();
      isLoadingSubscribedBrands.value = false;
      return;
    }

    final url = Uri.parse(ApiKey.getBrandsHistoryKey);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          // 'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}'
        },
        body: json.encode({"uuids": lastSubscribes, 'post': true}),
      );
      if (response.statusCode == 200) {
        // final data = json.decode(response.body);
        final jsonData = json.decode(response.body);
        subscribedBrands.value = await Isolate.run(() {
          return List<Map<String, dynamic>>.from(jsonData);
        });
        final List<Post> allPosts = [];

        for (final brand in jsonData) {
          final posts = brand['posts'] as List<dynamic>;
          allPosts.addAll(posts.map((postJson) => Post.fromJson(postJson)));
        }

        subscribeBrandPosts.value = allPosts;
        // final posts =
        //     await Isolate.run(() => parsePostsFromBrands(response.body));
        // subscribeBrandPosts.value = posts;
      }
      isLoadingSubscribedBrands.value = false;
      // if (response.statusCode == 406) {
      //   print('00000 favorites');
      //   await refreshAccesToken();
      // }

      // ignore: empty_catches
    } catch (e) {
    } finally {
      isLoadingSubscribedBrands.value = false;
    }
  }

  void addToSubscribes(String uuid) {
    if (!lastSubscribes.contains(uuid)) {
      // lastBrands.remove(uuid);
      lastSubscribes.add(uuid);
    }
    saveSubscribes();
  }

  void removeFromSubscribes(String uuid) {
    if (lastSubscribes.contains(uuid)) {
      // lastBrands.remove(uuid);
      lastSubscribes.remove(uuid);
    }
    saveSubscribes();
  }

  Future<void> refreshSubscribesData() async {
    await loadStoredSubscribes();
    await fetchBrandSubscribes();
  }

  @override
  void onClose() {
    _cancelFavoritesDebounce();
    super.onClose();
  }
}
