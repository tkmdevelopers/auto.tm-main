enum UserRole {
  admin,
  owner,
  user;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'owner':
        return UserRole.owner;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  String toJson() => name;
}

class UserProfile {
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String? location; // optional
  final String? avatar; // chosen single path (medium > large > small)
  final Map<String, String>? avatarVariants; // full size map if needed later
  final DateTime createdAt;
  final List<String>? brandUuid;
  final UserRole role;
  final List<String> access;

  UserProfile({
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    this.location,
    this.avatar,
    this.avatarVariants,
    required this.createdAt,
    this.brandUuid,
    required this.role,
    required this.access,
  });
}
