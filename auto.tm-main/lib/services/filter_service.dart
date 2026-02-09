import 'dart:convert';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';

class FilterService extends GetxService {
  static FilterService get to => Get.find<FilterService>();

  /// Fetch posts with filters
  Future<List<Post>> searchPosts(Map<String, dynamic> queryParams) async {
    try {
      final response = await ApiClient.to.dio.get('posts', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final rawList = (data is List 
            ? data 
            : json.decode(data is String ? data : '[]')) as List;
        
        return rawList
            .map((item) => PostLegacyExtension.fromJson(item is Map<String, dynamic> 
                ? item 
                : Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      Get.log('Error searching posts: $e');
      return [];
    }
  }

  /// Subscribe to a brand
  Future<bool> subscribeToBrand(String brandUuid) async {
    try {
      final response = await ApiClient.to.dio.post(
        'brands/subscribe',
        data: {'uuid': brandUuid},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Unsubscribe from a brand
  Future<bool> unsubscribeFromBrand(String brandUuid) async {
    try {
      final response = await ApiClient.to.dio.post(
        'brands/unsubscribe',
        data: {'uuid': brandUuid},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
