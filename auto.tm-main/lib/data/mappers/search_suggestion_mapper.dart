import 'package:auto_tm/domain/models/search_suggestion.dart';

class SearchSuggestionMapper {
  static SearchSuggestion fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      label: json['label'] as String? ?? '',
      brandLabel: json['brand_label'] as String? ?? '',
      modelLabel: json['model_label'] as String? ?? '',
      brandUuid: json['brand_uuid'] as String? ?? '',
      modelUuid: json['model_uuid'] as String? ?? '',
      compare: json['compare'] as String? ?? '',
    );
  }
}
