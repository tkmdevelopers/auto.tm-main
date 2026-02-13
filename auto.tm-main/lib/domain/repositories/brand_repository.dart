import 'package:auto_tm/domain/models/brand.dart';
import 'package:auto_tm/domain/models/car_model.dart';
import 'package:get/get.dart';

abstract class BrandRepository {
  // Reactive state
  RxList<Brand> get brands;
  RxList<CarModel> get models;
  RxBool get isLoadingBrands;
  RxBool get isLoadingModels;
  RxString get brandSearchQuery;
  RxString get modelSearchQuery;
  RxInt get nameResolutionTick;

  // Computed
  List<Brand> get filteredBrands;
  List<CarModel> get filteredModels;

  // Data fetching
  Future<void> fetchBrands({bool forceRefresh = false});
  Future<void> fetchModels(String brandUuid, {bool forceRefresh = false, bool showLoading = true});
  Future<List<Brand>> fetchBrandsByUuids(List<String> uuids);
  Future<void> ensureCachesLoaded();

  // Resolution
  String resolveBrandName(String idOrName);
  String resolveModelName(String idOrName);
  String resolveModelWithBrand(String modelId, String brandId);

  // History
  List<dynamic> getLocalHistory();
  Future<void> saveLocalHistory(List<dynamic> items);
}