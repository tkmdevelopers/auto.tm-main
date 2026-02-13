import 'package:auto_tm/domain/models/category.dart';
import 'package:auto_tm/data/mappers/post_mapper.dart';

class CategoryMapper {
  static Category fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid']?.toString() ?? '',
      nameTm: json['name']?['tm']?.toString() ?? '',
      nameEn: json['name']?['en']?.toString() ?? '',
      nameRu: json['name']?['ru']?.toString() ?? '',
      photo: json['photo']?['path']?['small']?.toString() ?? '',
      posts:
          (json['posts'] as List?)
              ?.map((p) => PostMapper.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
