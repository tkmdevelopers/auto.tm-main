import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Secure persistent storage for auth tokens.
///
/// Uses flutter_secure_storage (Keychain on iOS, EncryptedSharedPreferences
/// on Android) so tokens are encrypted at rest and unavailable to other apps.
class TokenStore extends GetxService {
  static const _keyAccess = 'ACCESS_TOKEN';
  static const _keyRefresh = 'REFRESH_TOKEN';
  static const _keyPhone = 'USER_PHONE';

  final FlutterSecureStorage _storage;

  /// Reactive auth flag. UI widgets can use `Obx(() => ...)` on this value
  /// to rebuild automatically when the user logs in or out.
  final RxBool isLoggedIn = false.obs;

  TokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static TokenStore get to => Get.find<TokenStore>();

  /// Hydrate [isLoggedIn] from secure storage.
  /// Must be called once after construction (e.g. in `main.dart`).
  Future<TokenStore> init() async {
    isLoggedIn.value = await hasTokens;
    return this;
  }

  // ── Read ──────────────────────────────────────────────────────

  Future<String?> get accessToken => _storage.read(key: _keyAccess);
  Future<String?> get refreshToken => _storage.read(key: _keyRefresh);
  Future<String?> get phone => _storage.read(key: _keyPhone);

  // ── Write ─────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? phone,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccess, value: accessToken),
      _storage.write(key: _keyRefresh, value: refreshToken),
      if (phone != null) _storage.write(key: _keyPhone, value: phone),
    ]);
    isLoggedIn.value = true;
  }

  Future<void> updateAccessToken(String token) async {
    await _storage.write(key: _keyAccess, value: token);
  }

  Future<void> updateRefreshToken(String token) async {
    await _storage.write(key: _keyRefresh, value: token);
  }

  Future<void> savePhone(String phone) async {
    await _storage.write(key: _keyPhone, value: phone);
  }

  // ── Delete ────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _keyAccess),
      _storage.delete(key: _keyRefresh),
      _storage.delete(key: _keyPhone),
    ]);
    isLoggedIn.value = false;
  }

  // ── Convenience ───────────────────────────────────────────────

  Future<bool> get hasTokens async {
    final access = await accessToken;
    return access != null && access.isNotEmpty;
  }
}
