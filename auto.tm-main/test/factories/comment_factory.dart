/// Factory for creating Comment test data
class CommentFactory {
  static Map<String, dynamic> makeJson({
    String? uuid,
    String? text,
    String? userId,
    String? postId,
    String? createdAt,
  }) {
    return {
      'uuid': uuid ?? 'comment_${DateTime.now().millisecondsSinceEpoch}',
      'text': text ?? 'This is a test comment',
      'userId': userId ?? 'user_123',
      'postId': postId ?? 'post_123',
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'user': {
        'uuid': userId ?? 'user_123',
        'name': 'Test User',
        'avatar': null,
      },
    };
  }

  /// Create a list of comments
  static List<Map<String, dynamic>> makeList({
    String? postId,
    int count = 5,
  }) {
    final comments = [
      'Great car!',
      'Is the price negotiable?',
      'What is the condition?',
      'Interested in buying',
      'Nice photos',
    ];
    return List.generate(
      count,
      (index) => makeJson(
        uuid: 'comment_$index',
        text: comments[index % comments.length],
        postId: postId,
      ),
    );
  }
}
