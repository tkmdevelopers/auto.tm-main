import 'package:auto_tm/domain/models/user_profile.dart';

class UserProfileMapper {
  static UserProfile fromJson(Map<String, dynamic> json) {
    String? selectedAvatar;
    Map<String, String>? variants;
    final avatarObj = json['avatar'];
    if (avatarObj is Map) {
      final pathObj = avatarObj['path'];
      if (pathObj is Map) {
        // Normalize keys to String->String
        variants = {
          for (final entry in pathObj.entries)
            if (entry.value != null)
              entry.key.toString(): entry.value.toString(),
        };
        selectedAvatar =
            variants['medium'] ?? variants['large'] ?? variants['small'];
      }
    }

    return UserProfile(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      location: json['location']?.toString(),
      avatar: selectedAvatar,
      avatarVariants: variants,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      brandUuid: const [],
      role: UserRole.fromString(json['role']?.toString()),
      access:
          (json['access'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
