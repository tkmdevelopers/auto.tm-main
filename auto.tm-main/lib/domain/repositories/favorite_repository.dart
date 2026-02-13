import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/models/brand.dart';

abstract class FavoriteRepository {
  Future<List<Post>> fetchFavoritePosts(List<String> uuids);
  Future<bool> subscribeToBrand(String brandUuid);
  Future<bool> unsubscribeFromBrand(String brandUuid);
  Future<List<Brand>> fetchSubscribedBrands(List<String> uuids);
}
