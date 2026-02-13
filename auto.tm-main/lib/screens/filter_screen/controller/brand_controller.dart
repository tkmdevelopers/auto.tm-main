import 'package:auto_tm/domain/models/brand_history_item.dart';
import 'package:auto_tm/domain/repositories/brand_repository.dart';
import 'package:get/get.dart';

class BrandController extends GetxController {
  final brandHistory = <BrandHistoryItem>[].obs;
  var isLoading = false.obs;

  BrandRepository get _brandRepository => Get.find<BrandRepository>();

  Future<void> loadStoredHistory() async {
    final storedData = _brandRepository.getLocalHistory();
    final items = storedData
        .map((e) => BrandHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    brandHistory.assignAll(items);
  }

  void saveHistory() {
    final data = brandHistory.map((e) => e.toJson()).toList();
    _brandRepository.saveLocalHistory(data);
  }

  void addToHistory({
    required String brandUuid,
    required String brandName,
    String? brandLogo,
    String? modelUuid,
    String? modelName,
    Map<String, dynamic>? filterState,
  }) {
    final newItem = BrandHistoryItem(
      brandUuid: brandUuid,
      brandName: brandName,
      brandLogo: brandLogo,
      modelUuid: modelUuid,
      modelName: modelName,
      filterState: filterState,
    );

    // 1. Remove exact duplicates (Brand + Model match)
    brandHistory.removeWhere((item) =>
        item.brandUuid == brandUuid && item.modelUuid == modelUuid);

    // 2. If we are adding a Brand + Model, remove any existing "Brand Only" entry 
    // for this brand to prevent "BMW" and "BMW 320" from co-existing.
    if (modelUuid != null) {
      brandHistory.removeWhere((item) => 
        item.brandUuid == brandUuid && item.modelUuid == null);
    } 
    // 3. If we are adding "Brand Only", check if we should remove specific models?
    // Usually, keeping specific models is better, but let's at least ensure 
    // the generic one doesn't push specific ones out if we want to keep history clean.
    // For now, we allow generic to be added, but it will be replaced next time a model is picked.

    // Insert at front
    brandHistory.insert(0, newItem);

    // Limit to 6 items
    if (brandHistory.length > 6) {
      brandHistory.removeLast();
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
  }
}