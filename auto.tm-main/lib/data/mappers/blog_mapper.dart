import 'package:auto_tm/domain/models/blog.dart';

class BlogMapper {
  static Blog fromJson(Map<String, dynamic> json) {
    return Blog(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: json['createdAt']?.toString() ?? '',
    );
  }
}
