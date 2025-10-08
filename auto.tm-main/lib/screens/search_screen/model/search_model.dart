class SearchModel {
  final String label;
  final String brandLabel;
  final String modelLabel;
  final String brandUuid;
  final String modelUuid;
  final String compare;

  SearchModel({
    required this.label,
    required this.brandLabel,
    required this.modelLabel,
    required this.brandUuid,
    required this.modelUuid,
    required this.compare,
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) {
    return SearchModel(
      label: json['label'] as String? ?? '',
      brandLabel: json['brand_label'] as String? ?? '',
      modelLabel: json['model_label'] as String? ?? '',
      brandUuid: json['brand_uuid'] as String? ?? '',
      modelUuid: json['model_uuid'] as String? ?? '',
      compare: json['compare'] as String? ?? '',
    );
  }
}
