class BannerModel {
  final String uuid;
  final String imagePath;

  BannerModel({
    required this.uuid,
    required this.imagePath,
  });

  // Factory method to create a BannerModel from JSON
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      uuid: json['uuid'],
      // imagePath: json['photo']?['path']['large'], // Handle nullable photo
      imagePath: json['photo']?['path']['medium'], // Handle nullable photo
    );
  }
}
