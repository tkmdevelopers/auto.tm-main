import 'dart:convert';
import 'dart:isolate';

import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class BrandController extends GetxController {
  final box = GetStorage();
  final lastBrands = <String>[].obs;
  var brands = <Map<String, dynamic>>[].obs;
  var isLodaing = false.obs;
  

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
    isLodaing.value = true;
    if (lastBrands.isEmpty) {
      brands.clear();
      isLodaing.value = false;
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
        body: json.encode({
          "uuids": lastBrands,
          'post' : false
        }),
      );

      if (response.statusCode == 200) {
        // final data = json.decode(response.body);
        brands.value = await Isolate.run(() {
          final jsonData = json.decode(response.body);
          return List<Map<String, dynamic>>.from(jsonData);
        });
      }
      isLodaing.value = false;
      // if (response.statusCode == 406) {
      //   print('00000 favorites');
      //   await refreshAccesToken();
      // }

      // ignore: empty_catches
    } catch (e) {
    } finally {
      isLodaing.value = false;
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
