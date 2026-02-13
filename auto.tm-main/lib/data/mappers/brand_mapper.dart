import 'package:auto_tm/data/dtos/common_dtos.dart';
import 'package:auto_tm/data/mappers/mapper_utils.dart';
import 'package:auto_tm/data/mappers/post_mapper.dart';
import 'package:auto_tm/domain/models/brand.dart';

class BrandMapper {
  static Brand fromJson(Map<String, dynamic> json) {
    final dto = BrandDto.fromJson(json);

    List<dynamic>? postsJson = json['posts'];
    final posts = postsJson
        ?.map((p) => PostMapper.fromJson(p as Map<String, dynamic>))
        .toList();

    return Brand(
      uuid: dto.uuid,
      name: dto.name,
      photoPath: MapperUtils.pickImageVariant(dto.photo?.path),
      posts: posts,
    );
  }
}
