import 'package:get/get.dart';


/// Post data transfer object - reflects the raw JSON from backend
class PostDto {
  final String uuid;
  final String? brandName;
  final String? modelName;
  final String? brandsId;
  final String? modelsId;
  final num? price;
  final num? year;
  final num? milleage;
  final String? engineType;
  final num? enginePower;
  final String? transmission;
  final String? condition;
  final String? vin;
  final String? currency;
  final String? description;
  final String? location;
  final bool? status;
  final bool? exchange;
  final bool? credit;
  final Map<String, dynamic>? personalInfo;
  final List<dynamic>? photo;
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic>? video;
  final Map<String, dynamic>? file;
  final String? createdAt;

  PostDto({
    required this.uuid,
    this.brandName,
    this.modelName,
    this.brandsId,
    this.modelsId,
    this.price,
    this.year,
    this.milleage,
    this.engineType,
    this.enginePower,
    this.transmission,
    this.condition,
    this.vin,
    this.currency,
    this.description,
    this.location,
    this.status,
    this.exchange,
    this.credit,
    this.personalInfo,
    this.photo,
    this.subscription,
    this.video,
    this.file,
    this.createdAt,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    return PostDto(
      uuid: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      brandName: json['brandName']?.toString(),
      modelName: json['modelName']?.toString(),
      brandsId: json['brandsId']?.toString(),
      modelsId: json['modelsId']?.toString(),
      price: json['price'] as num?,
      year: json['year'] as num?,
      milleage: json['milleage'] as num?,
      engineType: json['engineType']?.toString(),
      enginePower: json['enginePower'] as num?,
      transmission: json['transmission']?.toString(),
      condition: json['condition']?.toString(),
      vin: json['vin']?.toString(),
      currency: json['currency']?.toString(),
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      status: json['status'] as bool?,
      exchange: json['exchange'] as bool?,
      credit: json['credit'] as bool?,
      personalInfo: json['personalInfo'] as Map<String, dynamic>?,
      photo: json['photo'] as List<dynamic>?,
      subscription: json['subscription'] as Map<String, dynamic>?,
      video: json['video'] as Map<String, dynamic>?,
      file: json['file'] as Map<String, dynamic>?,
      createdAt: json['createdAt']?.toString(),
    );
  }
}
