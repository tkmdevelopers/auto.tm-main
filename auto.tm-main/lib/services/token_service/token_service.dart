import 'package:auto_tm/services/token_service/token_store.dart';

@Deprecated('Use TokenStore instead. This wrapper is kept for compatibility.')
class TokenService {
  Future<void> saveToken(String token, String key) async {
    if (key == 'ACCESS_TOKEN') {
      await TokenStore.to.updateAccessToken(token);
    } else if (key == 'REFRESH_TOKEN') {
      await TokenStore.to.updateRefreshToken(token);
    }
  }

  Future<String?> getToken() => TokenStore.to.accessToken;

  Future<void> deleteToken() async {
    await TokenStore.to.clearAll();
  }

  Future<void> clearStorage() async {
    await TokenStore.to.clearAll();
  }
}
