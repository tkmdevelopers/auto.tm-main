import 'package:auto_tm/domain/models/search_suggestion.dart';
import 'package:get/get.dart';

abstract class SearchRepository {
  RxBool get indexReady;
  RxBool get indexBuilding;
  Future<List<SearchSuggestion>> search(String query, {int offset = 0, int limit = 20});
  Future<void> ensureIndex();
}
