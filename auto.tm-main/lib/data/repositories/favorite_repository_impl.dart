import 'package:auto_tm/data/mappers/post_mapper.dart';
import 'package:auto_tm/data/mappers/brand_mapper.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/brand.dart';
import 'package:auto_tm/domain/repositories/favorite_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final ApiClient _apiClient;

  FavoriteRepositoryImpl(this._apiClient);

  @override
  Future<List<Post>> fetchFavoritePosts(List<String> uuids) async {
    if (uuids.isEmpty) return [];

    // Get.log('Fetching favorites for UUIDs: $uuids');

    final response = await _apiClient.dio.post(
      'posts/list',
      data: {'uuids': uuids, 'brand': 'true', 'model': 'true', 'photo': 'true'},
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      final data = response.data;
      // Get.log('Favorites API Response type: ${data.runtimeType}');
      if (data is List) {
        // Get.log('Favorites API returned ${data.length} items');
        return data
            .map((item) => PostMapper.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['data'] is List) {
         // Handle case where API returns wrapped response { "data": [...] }
         final list = data['data'] as List;
         // Get.log('Favorites API returned ${list.length} items (wrapped)');
         return list
            .map((item) => PostMapper.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } else {
      // Get.log('Favorites API failed with status: ${response.statusCode}');
    }
    return [];
  }

  @override
  Future<bool> subscribeToBrand(String brandUuid) async {
    final response = await _apiClient.dio.post(
      'brands/subscribe',
      data: {'uuid': brandUuid},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> unsubscribeFromBrand(String brandUuid) async {
    final response = await _apiClient.dio.post(
      'brands/unsubscribe',
      data: {'uuid': brandUuid},
    );
    return response.statusCode == 200;
  }

  @override
  Future<List<Brand>> fetchSubscribedBrands(List<String> uuids) async {
    if (uuids.isEmpty) return [];

    final response = await _apiClient.dio.post(
      'brands/list',
      data: {'uuids': uuids, 'post': true},
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      final data = response.data;
      if (data is List) {
        return data
            .map(
              (e) => BrandMapper.fromJson(
                e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    }
    return [];
  }
}
