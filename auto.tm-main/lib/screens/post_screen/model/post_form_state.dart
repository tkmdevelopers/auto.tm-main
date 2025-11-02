import 'package:collection/collection.dart';

/// Immutable representation of the post form state.
/// Gradually replaces scattered Rx primitives in PostController.
class PostFormState {
  final String brandUuid;
  final String modelUuid;
  final String brandName;
  final String modelName;
  final String condition;
  final String transmission;
  final String engineType;
  final int? year; // canonical year integer
  final String priceRaw; // raw user input before numeric parsing
  final String currency;
  final String location;
  final bool credit;
  final bool exchange;
  final String enginePowerRaw;
  final String milleageRaw;
  final String vin;
  final String description;
  final String phoneRaw; // subscriber digits (8) or full
  final String title;
  final bool phoneVerified;

  const PostFormState({
    this.brandUuid = '',
    this.modelUuid = '',
    this.brandName = '',
    this.modelName = '',
    this.condition = '',
    this.transmission = '',
    this.engineType = '',
    this.year,
    this.priceRaw = '',
    this.currency = 'TMT',
    this.location = '',
    this.credit = false,
    this.exchange = false,
    this.enginePowerRaw = '',
    this.milleageRaw = '',
    this.vin = '',
    this.description = '',
    this.phoneRaw = '',
    this.title = '',
    this.phoneVerified = false,
  });

  PostFormState copyWith({
    String? brandUuid,
    String? modelUuid,
    String? brandName,
    String? modelName,
    String? condition,
    String? transmission,
    String? engineType,
    int? year,
    String? priceRaw,
    String? currency,
    String? location,
    bool? credit,
    bool? exchange,
    String? enginePowerRaw,
    String? milleageRaw,
    String? vin,
    String? description,
    String? phoneRaw,
    String? title,
    bool? phoneVerified,
  }) => PostFormState(
    brandUuid: brandUuid ?? this.brandUuid,
    modelUuid: modelUuid ?? this.modelUuid,
    brandName: brandName ?? this.brandName,
    modelName: modelName ?? this.modelName,
    condition: condition ?? this.condition,
    transmission: transmission ?? this.transmission,
    engineType: engineType ?? this.engineType,
    year: year ?? this.year,
    priceRaw: priceRaw ?? this.priceRaw,
    currency: currency ?? this.currency,
    location: location ?? this.location,
    credit: credit ?? this.credit,
    exchange: exchange ?? this.exchange,
    enginePowerRaw: enginePowerRaw ?? this.enginePowerRaw,
    milleageRaw: milleageRaw ?? this.milleageRaw,
    vin: vin ?? this.vin,
    description: description ?? this.description,
    phoneRaw: phoneRaw ?? this.phoneRaw,
    title: title ?? this.title,
    phoneVerified: phoneVerified ?? this.phoneVerified,
  );

  bool get hasAnyInput =>
      [
        brandUuid,
        modelUuid,
        brandName,
        modelName,
        condition,
        transmission,
        engineType,
        priceRaw,
        location,
        enginePowerRaw,
        milleageRaw,
        vin,
        description,
        phoneRaw,
        title,
      ].any((e) => e.isNotEmpty) ||
      year != null ||
      credit ||
      exchange;

  Map<String, dynamic> toMap() => {
    'brandUuid': brandUuid,
    'modelUuid': modelUuid,
    'brandName': brandName,
    'modelName': modelName,
    'condition': condition,
    'transmission': transmission,
    'engineType': engineType,
    'year': year,
    'price': priceRaw,
    'currency': currency,
    'location': location,
    'credit': credit,
    'exchange': exchange,
    'enginePower': enginePowerRaw,
    'milleage': milleageRaw,
    'vin': vin,
    'description': description,
    'phone': phoneRaw,
    'title': title,
    'phoneVerified': phoneVerified,
  };

  static PostFormState fromMap(Map<String, dynamic> map) => PostFormState(
    brandUuid: map['brandUuid'] as String? ?? '',
    modelUuid: map['modelUuid'] as String? ?? '',
    brandName: map['brandName'] as String? ?? '',
    modelName: map['modelName'] as String? ?? '',
    condition: map['condition'] as String? ?? '',
    transmission: map['transmission'] as String? ?? '',
    engineType: map['engineType'] as String? ?? '',
    year: map['year'] is int
        ? map['year'] as int
        : (map['year'] is String ? int.tryParse(map['year'] as String) : null),
    priceRaw: map['price'] as String? ?? '',
    currency: map['currency'] as String? ?? 'TMT',
    location: map['location'] as String? ?? '',
    credit: map['credit'] == true,
    exchange: map['exchange'] == true,
    enginePowerRaw: map['enginePower'] as String? ?? '',
    milleageRaw: map['milleage'] as String? ?? '',
    vin: map['vin'] as String? ?? '',
    description: map['description'] as String? ?? '',
    phoneRaw: map['phone'] as String? ?? '',
    title: map['title'] as String? ?? '',
    phoneVerified: map['phoneVerified'] == true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostFormState &&
          brandUuid == other.brandUuid &&
          modelUuid == other.modelUuid &&
          brandName == other.brandName &&
          modelName == other.modelName &&
          condition == other.condition &&
          transmission == other.transmission &&
          engineType == other.engineType &&
          year == other.year &&
          priceRaw == other.priceRaw &&
          currency == other.currency &&
          location == other.location &&
          credit == other.credit &&
          exchange == other.exchange &&
          enginePowerRaw == other.enginePowerRaw &&
          milleageRaw == other.milleageRaw &&
          vin == other.vin &&
          description == other.description &&
          phoneRaw == other.phoneRaw &&
          title == other.title &&
          phoneVerified == other.phoneVerified;

  @override
  int get hashCode => const ListEquality().hash([
    brandUuid,
    modelUuid,
    brandName,
    modelName,
    condition,
    transmission,
    engineType,
    year,
    priceRaw,
    currency,
    location,
    credit,
    exchange,
    enginePowerRaw,
    milleageRaw,
    vin,
    description,
    phoneRaw,
    title,
    phoneVerified,
  ]);

  @override
  String toString() =>
      'PostFormState(brandUuid: $brandUuid, modelUuid: $modelUuid, price: $priceRaw, year: $year)';
}
