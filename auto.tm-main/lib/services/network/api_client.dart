import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/services/token_service/token_store.dart';

/// Central HTTP client built on Dio.
///
/// Features:
/// - Attaches the access token to every request via interceptor.
/// - On 401 `TOKEN_EXPIRED`, acquires a mutex, refreshes once, and retries.
/// - If refresh fails, clears tokens and routes to `/register`.
/// - Singleton via GetX (`Get.find<ApiClient>()`).
class ApiClient extends GetxService {
  late final Dio dio;

  /// Completer used as a mutex so only one refresh runs at a time.
  Completer<bool>? _refreshCompleter;

  static ApiClient get to => Get.find<ApiClient>();

  Future<ApiClient> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiKey.apiKey,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(this));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return this;
  }

  // ── Public helpers ──────────────────────────────────────────

  /// Try to refresh the token pair. Returns true on success.
  Future<bool> tryRefresh() async {
    // If another request already started a refresh, wait for it.
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    _refreshCompleter = Completer<bool>();

    try {
      final store = TokenStore.to;
      final refreshToken = await store.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      // Use a fresh Dio instance to avoid interceptor recursion
      final freshDio = Dio(BaseOptions(
        baseUrl: ApiKey.apiKey,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await freshDio.post(
        'auth/refresh',
        options: Options(headers: {
          'Authorization': 'Bearer $refreshToken',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;

        if (newAccess != null && newRefresh != null) {
          await store.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      if (kDebugMode) print('[ApiClient] Refresh failed: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Clear tokens and navigate to login.
  Future<void> forceLogout() async {
    await TokenStore.to.clearAll();
    Get.offAllNamed('/register');
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Interceptor
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  _AuthInterceptor(this._client);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach access token if available
    final accessToken = await TokenStore.to.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;

    // Only handle 401 with TOKEN_EXPIRED code
    if (response != null && response.statusCode == 401) {
      final data = response.data;
      final code = data is Map ? data['code'] : null;

      if (code == 'TOKEN_EXPIRED') {
        // Attempt refresh + retry
        final refreshed = await _client.tryRefresh();
        if (refreshed) {
          // Retry original request with the new access token
          try {
            final opts = err.requestOptions;
            final newAccess = await TokenStore.to.accessToken;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final retryResponse = await _client.dio.fetch(opts);
            return handler.resolve(retryResponse);
          } catch (retryErr) {
            // Retry also failed — fall through to rejection
          }
        }

        // Refresh failed or retry failed — force logout
        await _client.forceLogout();
        return handler.reject(err);
      }
    }

    handler.next(err);
  }
}
