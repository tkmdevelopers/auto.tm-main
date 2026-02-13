class Comment {
  final String uuid;
  final String postId;
  final String? replyTo;
  final String message;
  final String? userName;
  final String? userAvatar;
  final String createdAt;

  Comment({
    required this.uuid,
    required this.postId,
    this.replyTo,
    required this.message,
    this.userName,
    this.userAvatar,
    required this.createdAt,
  });
}
