import 'dart:async';

import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/services/favorite_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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

    try {
      final posts = await FavoriteService.to.fetchFavoritePosts(favorites);
      favoriteProducts.assignAll(posts);
    } catch (e) {
       // Controller-level error handling if needed, or silent fail as before
    }
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
      final success = await FavoriteService.to.subscribeToBrand(brandUuid);

      if (success) {
        Get.snackbar(
          'common_success'.tr,
          'favourites_subscribe_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        addToSubscribes(brandUuid);
        fetchBrandSubscribes();
      }
    } catch (e) {
      // Auth/errors handled by ApiClient interceptor
    } finally {
      isLoadingSubscribedBrands.value = false;
    }
  }

  Future<void> unSubscribeFromBrand(String brandUuid) async {
    try {
      final success = await FavoriteService.to.unsubscribeFromBrand(brandUuid);

      if (success) {
        Get.snackbar(
          'common_success'.tr,
          'favourites_unsubscribe_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        removeFromSubscribes(brandUuid);
        fetchBrandSubscribes();
      }
    } catch (e) {
      // Auth/errors handled by ApiClient interceptor
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

    try {
      final jsonData = await FavoriteService.to.fetchSubscribedBrands(lastSubscribes);
      
      if (jsonData.isNotEmpty) {
        subscribedBrands.value = jsonData;
        final List<Post> allPosts = [];
        for (final map in jsonData) {
          final postsList = map['posts'];
          if (postsList is List) {
            allPosts.addAll(
              postsList.map((postJson) => PostLegacyExtension.fromJson(postJson as Map<String, dynamic>)),
            );
          }
        }
        subscribeBrandPosts.value = allPosts;
      }
    } catch (e) {
      // ignore
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
