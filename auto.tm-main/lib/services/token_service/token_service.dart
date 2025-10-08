import 'package:get_storage/get_storage.dart';

class TokenService {
  final GetStorage _storage = GetStorage();

  void saveToken(String token, String key) {
    _storage.write(key, token);
  }

  String? getToken() {
    return _storage.read('ACCESS_TOKEN');
  }

  void deleteToken() {
    _storage.remove('authToken');
  }

  void clearStorage() {
    _storage.erase();
  }
}