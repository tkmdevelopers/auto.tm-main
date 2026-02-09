class PostFilter {
  final String? brandFilter;
  final String? modelFilter;
  final String? categoryFilter;
  final String? region;
  final String? location;
  final String? color;
  final bool? credit;
  final bool? exchange;
  final String? transmission;
  final String? engineType;
  final String? enginePower;
  final String? milleage;
  final String? condition;
  final String? minYear;
  final String? maxYear;
  final String? minPrice;
  final String? maxPrice;
  final List<String>? subFilter;
  final String? sortBy;
  final String? sortAs;

  PostFilter({
    this.brandFilter,
    this.modelFilter,
    this.categoryFilter,
    this.region,
    this.location,
    this.color,
    this.credit,
    this.exchange,
    this.transmission,
    this.engineType,
    this.enginePower,
    this.milleage,
    this.condition,
    this.minYear,
    this.maxYear,
    this.minPrice,
    this.maxPrice,
    this.subFilter,
    this.sortBy,
    this.sortAs,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (brandFilter != null) 'brandFilter': brandFilter,
      if (modelFilter != null) 'modelFilter': modelFilter,
      if (categoryFilter != null) 'categoryFilter': categoryFilter,
      if (region != null) 'region': region,
      if (location != null) 'location': location,
      if (color != null) 'color': color,
      if (credit != null) 'credit': credit,
      if (exchange != null) 'exchange': exchange,
      if (transmission != null) 'transmission': transmission,
      if (engineType != null) 'engineType': engineType,
      if (enginePower != null) 'enginePower': enginePower,
      if (milleage != null) 'milleage': milleage,
      if (condition != null) 'condition': condition,
      if (minYear != null) 'minYear': minYear,
      if (maxYear != null) 'maxYear': maxYear,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (subFilter != null) 'subFilter': subFilter,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortAs != null) 'sortAs': sortAs,
    };
  }
}
