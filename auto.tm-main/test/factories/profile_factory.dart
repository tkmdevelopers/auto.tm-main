import 'package:auto_tm/screens/profile_screen/model/profile_model.dart';

class ProfileFactory {
  static ProfileModel make({
    String? uuid,
    String? name,
    String? phone,
    String? email,
    String? location,
  }) {
    return ProfileModel(
      uuid: uuid ?? 'user_123',
      name: name ?? 'Test User',
      email: email ?? 'test@example.com',
      phone: phone ?? '+99365000000',
      location: location ?? 'Aşgabat',
      createdAt: DateTime.now(),
      brandUuid: [],
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
        }
      }
    };
  }
}
