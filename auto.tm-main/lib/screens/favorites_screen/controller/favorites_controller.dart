import 'dart:async';

import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/brand.dart';
import 'package:auto_tm/domain/repositories/favorite_repository.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class FavoritesController extends GetxController {
  final box = GetStorage();
  final FavoriteRepository _favoriteRepository;

  FavoritesController() : _favoriteRepository = Get.find<FavoriteRepository>();
  final isFavorite = false.obs;
  final favoriteProducts = <Post>[].obs;
  final favorites = <String>[].obs;
  final RxBool showPosts = true.obs;

  final RxBool isLoadingPosts = false.obs;
  final RxBool isLoadingSubscribedBrands = false.obs;
  final RxBool isRefreshingToken = false.obs;
  final lastSubscribes = <String>[].obs;
  final RxList<Brand> subscribedBrands = <Brand>[].obs;
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
    // Get.log('Fetching favorite products for ${favorites.length} items: $favorites');
    if (favorites.isEmpty) {
      favoriteProducts.clear();
      return;
    }

    try {
      final posts = await _favoriteRepository.fetchFavoritePosts(favorites);
      // Get.log('Fetched ${posts.length} favorite products');
      favoriteProducts.assignAll(posts);
    } catch (e) {
      Get.log('Error fetching favorite products: $e');
    }
  }

  void toggleFavorite(String uuid) {
    // Get.log('Toggling favorite: $uuid');
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
    // Get.log('New favorites list: $favorites');
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
      final success = await _favoriteRepository.subscribeToBrand(brandUuid);

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
      final success = await _favoriteRepository.unsubscribeFromBrand(brandUuid);

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
      final brands = await _favoriteRepository.fetchSubscribedBrands(
        lastSubscribes,
      );

      if (brands.isNotEmpty) {
        subscribedBrands.assignAll(brands);
        final List<Post> allPosts = [];
        for (final brand in brands) {
          if (brand.posts != null) {
            allPosts.addAll(brand.posts!);
          }
        }
        subscribeBrandPosts.assignAll(allPosts);
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
