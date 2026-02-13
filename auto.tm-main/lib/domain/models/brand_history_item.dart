class BrandHistoryItem {
  final String brandUuid;
  final String brandName;
  final String? brandLogo;
  final String? modelUuid;
  final String? modelName;
  final Map<String, dynamic>? filterState; // Snapshot of all other filter traits

  BrandHistoryItem({
    required this.brandUuid,
    required this.brandName,
    this.brandLogo,
    this.modelUuid,
    this.modelName,
    this.filterState,
  });

  Map<String, dynamic> toJson() {
    return {
      'brandUuid': brandUuid,
      'brandName': brandName,
      'brandLogo': brandLogo,
      'modelUuid': modelUuid,
      'modelName': modelName,
      'filterState': filterState,
    };
  }

  factory BrandHistoryItem.fromJson(Map<String, dynamic> json) {
    return BrandHistoryItem(
      brandUuid: json['brandUuid'] as String,
      brandName: json['brandName'] as String,
      brandLogo: json['brandLogo'] as String?,
      modelUuid: json['modelUuid'] as String?,
      modelName: json['modelName'] as String?,
      filterState: json['filterState'] != null 
          ? Map<String, dynamic>.from(json['filterState'] as Map) 
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandHistoryItem &&
          runtimeType == other.runtimeType &&
          brandUuid == other.brandUuid &&
          modelUuid == other.modelUuid;

  @override
  int get hashCode => brandUuid.hashCode ^ modelUuid.hashCode;
}