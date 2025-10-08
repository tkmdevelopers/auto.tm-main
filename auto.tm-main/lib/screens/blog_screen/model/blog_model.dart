class Blog {
  final String uuid;
  final String title;
  final String description;
  // final String authorName;
  // final String authorEmail;
  // final String authorPhoto;
  final String date;
  // final String previewText;
  // final String thumbnail;
  // final int likes;
  // final int comments;
  
  Blog({
    required this.uuid,
    required this.title,
    required this.description,
    // required this.authorName,
    // required this.authorEmail,
    required this.date,
    // required this.previewText,
    // required this.thumbnail,
    // required this.likes,
    // required this.comments,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      uuid: json['uuid'],
      title: json['title'],
      description: json['description']??'',
      // authorName: json['user']['name'],
      // authorEmail: json['user']['email'],
      date: json['createdAt'],
      // previewText: json['previewText'],
      // thumbnail: json['thumbnail'],
      // likes: json['likes'],
      // comments: json['comments'],
    );
  }
}