
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/models/post_dtos.dart';

class Category {
  final String uuid;
  final String nameTm;
  final String nameEn;
  final String nameRu;
  final String photo;
  final List<Post> posts;

  Category({
    required this.uuid,
    required this.nameTm,
    required this.nameEn,
    required this.nameRu,
    required this.photo,
    required this.posts,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid'] ?? '',
      nameTm: json['name']['tm'] ?? '',
      nameEn: json['name']['en'] ?? '',
      nameRu: json['name']['ru'] ?? '',
      photo: json['photo']['path']['small'] ?? '',
      // photo: '',
      // products: List<Product>.from(json['products'].map((x) => Product.fromJson(x))),
      posts: (json['posts'] as List)
          .map((productJson) => PostLegacyExtension.fromJson(productJson))
          .toList(),
    );
    
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'uuid': uuid,

  //     'isActive': isActive,
  //     'createdAt': createdAt,
  //     'updatedAt': updatedAt,
  //     'categoryId': categoryId,
  //     'photo': photo.toJson(),
  //     'products': products.map((x) => x.toJson()).toList(),
  //   };
  // }
}

// class Photo {
//   final String uuid;
//   final String path;
//   final String createdAt;
//   final String updatedAt;
//   final String? categoryId;
//   final String? subcategoryId;
//   final String? bannerId;

//   Photo({
//     required this.uuid,
//     required this.path,
//     required this.createdAt,
//     required this.updatedAt,
//     this.categoryId,
//     this.subcategoryId,
//     this.bannerId,
//   });

//   factory Photo.fromJson(Map<String, dynamic> json) {
//     return Photo(
//       uuid: json['uuid'],
//       path: json['path'],
//       createdAt: json['createdAt'],
//       updatedAt: json['updatedAt'],
//       categoryId: json['categoryId'],
//       subcategoryId: json['subcategoryId'],
//       bannerId: json['bannerId'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'uuid': uuid,
//       'path': path,
//       'createdAt': createdAt,
//       'updatedAt': updatedAt,
//       'categoryId': categoryId,
//       'subcategoryId': subcategoryId,
//       'bannerId': bannerId,
//     };
//   }
// }