/// Abstract interface for token storage and retrieval.
/// Decouples repositories from specific storage implementations (GetStorage, SharedPreferences, etc.)
abstract class AuthTokenProvider {
  /// Retrieves the current access token, or null if not available
  String? getAccessToken();

  /// Retrieves the current refresh token, or null if not available
  String? getRefreshToken();

  /// Stores a new access token
  Future<void> setAccessToken(String token);

  /// Stores a new refresh token (optional operation)
  Future<void> setRefreshToken(String token);
}

/// Production implementation using GetStorage
///
/// This adapter allows PostRepository to remain storage-agnostic
/// while still leveraging GetStorage for actual persistence.
class GetStorageAuthTokenProvider implements AuthTokenProvider {
  final dynamic _box; // Using dynamic to avoid direct GetStorage dependency in interface

  GetStorageAuthTokenProvider(this._box);

  @override
  String? getAccessToken() {
    return _box.read('ACCESS_TOKEN') as String?;
  }

  @override
  String? getRefreshToken() {
    return _box.read('REFRESH_TOKEN') as String?;
  }

  @override
  Future<void> setAccessToken(String token) async {
    await _box.write('ACCESS_TOKEN', token);
  }

  @override
  Future<void> setRefreshToken(String token) async {
    await _box.write('REFRESH_TOKEN', token);
  }
}

/// Test implementation for unit testing without GetStorage initialization
///
/// Stores tokens in-memory for fast, isolated testing.
/// Useful in test scenarios where GetStorage cannot be initialized.
class InMemoryAuthTokenProvider implements AuthTokenProvider {
  String? _accessToken;
  String? _refreshToken;

  InMemoryAuthTokenProvider({
    String? initialAccessToken,
    String? initialRefreshToken,
  })  : _accessToken = initialAccessToken,
        _refreshToken = initialRefreshToken;

  @override
  String? getAccessToken() => _accessToken;

  @override
  String? getRefreshToken() => _refreshToken;

  @override
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
  }

  /// Test helper: Clear all tokens
  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}
