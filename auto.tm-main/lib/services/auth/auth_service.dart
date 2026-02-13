import 'package:auto_tm/domain/repositories/auth_repository.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'auth_models.dart';
import 'phone_formatter.dart';

/// Central authentication service (GetxService).
///
/// Manages [AuthSession] reactive state.
/// Uses [AuthRepository] for data operations.
class AuthService extends GetxService {
  /// Reactive session — null when logged out.
  final Rx<AuthSession?> currentSession = Rx<AuthSession?>(null);

  final AuthRepository _repository;

  AuthService() : _repository = Get.find<AuthRepository>();

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
    return _repository.sendOtp(full);
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

    final result = await _repository.verifyOtp(full, code);

    if (result.success &&
        result.accessToken != null &&
        result.refreshToken != null) {
      final session = AuthSession(
        phone: full,
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
      );
      currentSession.value = session;
      await TokenStore.to.saveTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken!,
        phone: full,
      );
    }

    return result;
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
    await _repository.logout();

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
        pc.location.value = 'Aşgabat';
        pc.nameController.clear();
        pc.locationController.text = 'Aşgabat';
        pc.hasLoadedProfile.value = false;
      } catch (_) {}
    }
  }
}
