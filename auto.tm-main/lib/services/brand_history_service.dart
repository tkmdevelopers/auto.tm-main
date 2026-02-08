import 'dart:isolate';

import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';

/// Service for handling brand history API calls.
/// This keeps networking logic out of controllers.
class BrandHistoryService extends GetxService {
  final ApiClient _apiClient;

  BrandHistoryService(this._apiClient);

  /// Fetch brand details by UUIDs
  Future<List<Map<String, dynamic>>> fetchBrandsByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return [];

    try {
      final response = await _apiClient.dio.post(
        'brands/history',
        data: {
          'uuids': uuids,
          'post': false,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Use isolate for JSON parsing to avoid UI jank
        return await Isolate.run(() {
          return List<Map<String, dynamic>>.from(response.data);
        });
      }
      return [];
    } catch (e) {
      Get.log('Error fetching brands by UUIDs: $e');
      return [];
    }
  }
}
