import 'package:auto_tm/services/brand_history_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class BrandController extends GetxController {
  final box = GetStorage();
  final lastBrands = <String>[].obs;
  var brands = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  
  BrandHistoryService get _brandHistoryService => Get.find<BrandHistoryService>();

  List<String> loadHistory() {
    return box.read<List<String>>('brand_history') ?? [];
  }

  Future<void> loadStoredHistory() async {
    List<String>? storedHistory =
        box.read<List>('brand_history')?.cast<String>();
    if (storedHistory != null) {
      lastBrands.assignAll(storedHistory);
    }
  }

// Save Favorites to GetStorage
  void saveHistory() {
    box.write('brand_history', lastBrands.toList());
  }

  Future<void> fetchBrandHistory() async {
    isLoading.value = true;
    if (lastBrands.isEmpty) {
      brands.clear();
      isLoading.value = false;
      return;
    }

    try {
      final result = await _brandHistoryService.fetchBrandsByUuids(lastBrands.toList());
      brands.value = result;
    } catch (e) {
      // Error already logged in service
    } finally {
      isLoading.value = false;
    }
  }

  void addToHistory(String uuid) {
    if (!lastBrands.contains(uuid)) {
      // lastBrands.remove(uuid);
      lastBrands.add(uuid);
    }
    saveHistory();
  }

  @override
  void onInit() {
    super.onInit();
    loadStoredHistory();
  }

  Future<void> refreshData() async {
    await loadStoredHistory();
    await fetchBrandHistory();
  }
}
