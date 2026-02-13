import 'package:auto_tm/domain/models/post.dart';

class Brand {
  final String uuid;
  final String name;
  final String? photoPath;
  final List<Post>? posts;

  Brand({required this.uuid, required this.name, this.photoPath, this.posts});
}
