import 'package:auto_tm/domain/models/comment.dart';

class CommentMapper {
  static Comment fromJson(Map<String, dynamic> json) {
    String? userName;
    String? userAvatar;

    final personal = json['personalInfo'];
    if (personal is Map) {
      userName = personal['name']?.toString();
      final avatar = personal['avatar'];
      if (avatar is Map) {
        userAvatar =
            avatar['path']?['small']?.toString() ??
            avatar['path']?['medium']?.toString();
      }
    }

    return Comment(
      uuid: json['uuid']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      replyTo: json['replyTo']?.toString(),
      message: json['message']?.toString() ?? '',
      userName: userName,
      userAvatar: userAvatar,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
