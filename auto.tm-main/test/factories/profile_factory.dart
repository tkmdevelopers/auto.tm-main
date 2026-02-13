import 'package:auto_tm/domain/models/user_profile.dart';

class ProfileFactory {
  static UserProfile make({
    String? uuid,
    String? name,
    String? phone,
    String? email,
    String? location,
  }) {
    return UserProfile(
      uuid: uuid ?? 'user_123',
      name: name ?? 'Test User',
      email: email ?? 'test@example.com',
      phone: phone ?? '+99365000000',
      location: location ?? 'Aşgabat',
      createdAt: DateTime.now(),
      brandUuid: [],
      role: UserRole.user,
      access: [],
    );
  }

  static Map<String, dynamic> makeJson({
    String? uuid,
    String? name,
    String? phone,
  }) {
    return {
      'uuid': uuid ?? 'user_123',
      'name': name ?? 'Test User',
      'email': 'test@example.com',
      'phone': phone ?? '+99365000000',
      'location': 'Aşgabat',
      'createdAt': DateTime.now().toIso8601String(),
      'avatar': {
        'path': {
          'small': 'small.jpg',
          'medium': 'medium.jpg',
          'large': 'large.jpg',
        },
      },
    };
  }
}
