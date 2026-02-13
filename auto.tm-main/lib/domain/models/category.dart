import 'package:auto_tm/domain/models/post.dart';

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
}
