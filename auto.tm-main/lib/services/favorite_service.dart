import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';

class FavoriteService extends GetxService {
  static FavoriteService get to => Get.find<FavoriteService>();

  /// Fetch favorite posts by their UUIDs
  Future<List<Post>> fetchFavoritePosts(List<String> uuids) async {
    if (uuids.isEmpty) return [];

    try {
      final response = await ApiClient.to.dio.post(
        'posts/list',
        data: {
          'uuids': uuids,
          'brand': 'true',
          'model': 'true',
          'photo': 'true',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          return data
              .map((item) => PostLegacyExtension.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // Re-throw or handle? Controller currently catches generic. 
      // We'll let controller handle logic or suppress, but logging here is good.
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
      // ApiClient interceptor mostly handles auth errors
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
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch list of subscribed brands (and optionally their posts)
  /// Returns raw List<Map> because the controller logic parses it manually including nested 'posts'
  /// TODO: Create a proper model for this response
  Future<List<Map<String, dynamic>>> fetchSubscribedBrands(List<String> uuids) async {
    if (uuids.isEmpty) return [];

    try {
      final response = await ApiClient.to.dio.post(
        'brands/list',
        data: {'uuids': uuids, 'post': true},
      );
      
      if (response.statusCode == 200 && response.data != null) {
         final data = response.data;
         if (data is List) {
            return data
                .map((e) => e is Map<String, dynamic> 
                    ? e 
                    : Map<String, dynamic>.from(e as Map))
                .toList();
         }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
