import 'package:get/get.dart';

class SubscriptionModel {
  final String uuid;
  final Map<String, String> title;
  final Map<String, String> description;
  final int price;
  final String color;
  final String path;

  SubscriptionModel({
    required this.uuid,
    required this.title,
    required this.description,
    required this.price,
    required this.color,
    required this.path,
  });

  // Localized name getter
  String get localizedName {
    final locale = Get.locale?.languageCode ?? 'en';
    return title[locale] ?? title['en'] ?? 'Unnamed';
  }
  String get localizedDescription {
    final locale = Get.locale?.languageCode ?? 'en';
    return description[locale] ?? description['en'] ?? 'Unnamed';
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      uuid: json['uuid'],
      title: Map<String, String>.from(json['name']),
      description: Map<String, String>.from(json['description']),
      price: (json['price'] as num?)?.toInt() ?? 0,

      color: (json['color'] as String?) ?? '',

      path: (json['photo'] is Map<String, dynamic> && 
              (json['photo'] as Map<String, dynamic>)['path'] is Map<String, dynamic> && 
              (json['photo'] as Map<String, dynamic>)['path']['small'] is String &&
              (json['photo'] as Map<String, dynamic>)['path']['small'].isNotEmpty 
             )
            ? (json['photo']['path']['small'] as String) 
            : '',
    );
  }
}

// class SubscriptionModel {
//   final String uuid;
//   final String title;
//   final String description;
//   final int price;
//   final String color;

//   SubscriptionModel({
//     required this.uuid,
//     required this.title,
//     required this.description,
//     required this.price,
//     required this.color,
//   });

//   factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
//     return SubscriptionModel(
//       uuid: json['uuid'],
//       title: json['name']['en'] ?? '',
//       description: json['description']['en']??'',
//       price: json['price'],
//       color: json['color'],
//     );
//   }
// }

class SubscriptionRequestModel {
  final String location;
  final String phone;
  final String subscriptionId;

  SubscriptionRequestModel({
    required this.location,
    required this.phone,
    required this.subscriptionId,
  });

  Map<String, dynamic> toJson() => {
        'location': location,
        'phone': phone,
        'subscriptionId': subscriptionId,
      };
}
