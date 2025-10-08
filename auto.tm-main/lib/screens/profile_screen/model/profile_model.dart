                                          class ProfileModel {
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String? location; // Make location optional
  final String? avatar;
  final DateTime createdAt;
  final List<String>? brandUuid;

  ProfileModel({
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    this.location, // Make location optional
    this.avatar,
    required this.createdAt,
    this.brandUuid,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      location: json['location']?.toString(),
      avatar: json['avatar']?['path']?.toString(),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now(),
      brandUuid: [],
    );
  }
}
