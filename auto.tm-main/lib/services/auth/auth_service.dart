import 'package:get/get.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:flutter/foundation.dart';
import 'auth_models.dart';
import 'phone_formatter.dart';

/// Central authentication service (GetxService).
///
/// Uses [ApiClient] (Dio) for HTTP and [TokenStore] (flutter_secure_storage)
/// for persisting tokens. OTP send/verify are now POST requests with JSON body.
class AuthService extends GetxService {
  /// Reactive session — null when logged out.
  final Rx<AuthSession?> currentSession = Rx<AuthSession?>(null);

  static AuthService get to => Get.find<AuthService>();

  // ── Initialization ────────────────────────────────────────────

  Future<AuthService> init() async {
    // Restore session from secure storage
    final store = TokenStore.to;
    final phone = await store.phone;
    final access = await store.accessToken;
    final refresh = await store.refreshToken;
    if (phone != null && access != null && access.isNotEmpty) {
      currentSession.value = AuthSession(
        phone: phone,
        accessToken: access,
        refreshToken: refresh,
      );
    }
    return this;
  }

  // ── OTP ───────────────────────────────────────────────────────

  Future<OtpSendResult> sendOtp(String subscriberDigits) async {
    if (!PhoneFormatter.isValidSubscriber(subscriberDigits)) {
      return const OtpSendResult(
        success: false,
        message: 'Invalid subscriber digits',
      );
    }
    final full = PhoneFormatter.buildFullDigits(subscriberDigits);
    try {
      final resp = await ApiClient.to.dio.post(
        'otp/send',
        data: {'phone': full},
      );
      final body = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (kDebugMode) print('[auth] sendOtp status=${resp.statusCode}');
      final success = _isOtpSendSuccess(body, resp.statusCode ?? 0);
      return OtpSendResult(
        success: success,
        message: body['message']?.toString(),
        otpId: body['otpId']?.toString(),
        raw: body,
      );
    } catch (e) {
      return OtpSendResult(success: false, message: 'Exception: $e');
    }
  }

  Future<OtpVerifyResult> verifyOtp(
    String subscriberDigits,
    String code,
  ) async {
    if (!PhoneFormatter.isValidSubscriber(subscriberDigits)) {
      return const OtpVerifyResult(
        success: false,
        message: 'Invalid subscriber',
      );
    }
    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
      return const OtpVerifyResult(
        success: false,
        message: 'Invalid OTP length',
      );
    }
    final full = PhoneFormatter.buildFullDigits(subscriberDigits);
    try {
      final resp = await ApiClient.to.dio.post(
        'otp/verify',
        data: {'phone': full, 'otp': code},
      );
      final body = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (kDebugMode) print('[auth] verifyOtp status=${resp.statusCode}');
      final success = _isOtpVerifySuccess(body, resp.statusCode ?? 0);
      if (success) {
        final access =
            body['accessToken']?.toString() ?? body['token']?.toString();
        final refresh = body['refreshToken']?.toString();
        if (access != null && refresh != null) {
          final session = AuthSession(
            phone: full,
            accessToken: access,
            refreshToken: refresh,
          );
          currentSession.value = session;
          await TokenStore.to.saveTokens(
            accessToken: access,
            refreshToken: refresh,
            phone: full,
          );
        }
        return OtpVerifyResult(
          success: true,
          accessToken: access,
          refreshToken: refresh,
          raw: body,
          message: body['message']?.toString(),
        );
      }
      return OtpVerifyResult(
        success: false,
        raw: body,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return OtpVerifyResult(success: false, message: 'Exception: $e');
    }
  }

  // ── Token Refresh ─────────────────────────────────────────────

  /// Delegates to ApiClient which handles mutex + rotation.
  /// Updates the in-memory session after a successful refresh.
  Future<AuthSession?> refreshTokens() async {
    final ok = await ApiClient.to.tryRefresh();
    if (!ok) return null;
    // Re-read from store (ApiClient already saved new tokens)
    final store = TokenStore.to;
    final access = await store.accessToken;
    final refresh = await store.refreshToken;
    if (access != null && currentSession.value != null) {
      final updated = currentSession.value!.copyWith(
        accessToken: access,
        refreshToken: refresh,
      );
      currentSession.value = updated;
      return updated;
    }
    return null;
  }

  // ── Logout ────────────────────────────────────────────────────

  Future<void> logout() async {
    // Tell the backend to invalidate the refresh token
    try {
      await ApiClient.to.dio.post('auth/logout');
    } catch (_) {
      // Best-effort; even if it fails, clear local state.
    }

    currentSession.value = null;
    await TokenStore.to.clearAll();
    _notifyControllersOfLogout();
  }

  void _notifyControllersOfLogout() {
    if (Get.isRegistered<ProfileController>()) {
      try {
        final pc = Get.find<ProfileController>();
        pc.profile.value = null;
        pc.name.value = '';
        pc.phone.value = '';
        pc.location.value = ProfileController.defaultLocation;
        pc.nameController.clear();
        pc.locationController.text = ProfileController.defaultLocation;
        pc.hasLoadedProfile.value = false;
      } catch (_) {}
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  bool _isOtpSendSuccess(Map body, int status) {
    if (status == 200 || status == 201) {
      if (body['result'] == true || body['response'] == true) return true;
      if (body['success'] == true) return true;
      if ((body['status'] is String) &&
          body['status'].toString().toLowerCase() == 'ok') {
        return true;
      }
      if (body.containsKey('otpId') ||
          body.containsKey('otp') ||
          body.containsKey('code')) {
        return true;
      }
      if (body.isNotEmpty) return true;
    }
    return false;
  }

  bool _isOtpVerifySuccess(Map body, int status) {
    if (status == 200 || status == 201) {
      if (body['result'] == true || body['response'] == true) return true;
      if (body['verified'] == true || body['success'] == true) return true;
      if ((body['status'] is String) &&
          body['status'].toString().toLowerCase() == 'ok') {
        return true;
      }
      if (body.containsKey('token') || body.containsKey('accessToken')) {
        return true;
      }
    }
    return false;
  }
}
