import 'dart:convert';
import 'package:get/get.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'auth_models.dart';
import 'phone_formatter.dart';
import '../../utils/key.dart';
import '../../utils/cached_image_helper.dart';
import 'package:flutter/foundation.dart';

class AuthService extends GetxService {
  final _box = GetStorage();
  final _client = http.Client();

  // Reactive session (null when logged out)
  final Rx<AuthSession?> currentSession = Rx<AuthSession?>(null);

  static AuthService get to => Get.find<AuthService>();

  Future<AuthService> init() async {
    // Attempt restore
    final phone = _box.read('USER_PHONE');
    final access = _box.read('ACCESS_TOKEN');
    final refresh = _box.read('REFRESH_TOKEN');
    if (phone is String && access is String) {
      currentSession.value = AuthSession(
        phone: phone,
        accessToken: access,
        refreshToken: refresh is String ? refresh : null,
      );
    }
    return this;
  }

  Future<OtpSendResult> sendOtp(String subscriberDigits) async {
    if (!PhoneFormatter.isValidSubscriber(subscriberDigits)) {
      return const OtpSendResult(
        success: false,
        message: 'Invalid subscriber digits',
      );
    }
    final full = PhoneFormatter.buildFullDigits(
      subscriberDigits,
    ); // 993 + digits
    final uri = Uri.parse('${ApiKey.sendOtpKey}?phone=$full');
    try {
      final started = DateTime.now();
      final resp = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[auth] sendOtp status=${resp.statusCode} elapsed=${elapsedMs}ms size=${resp.body.length} bodyKeys=${body is Map ? (body.keys.toList()) : []} body=$body',
        );
      }
      final success = _isOtpSendSuccess(body, resp.statusCode);
      // Derive a clearer message if backend only returns generic text
      String? message = body['message']?.toString();
      if (!success) {
        if (resp.statusCode == 400) {
          message ??= 'Nädogry telefon belgisi (400)';
        } else if (resp.statusCode == 404) {
          message ??= 'OTP hyzmaty tapylmady (404)';
        } else if (resp.statusCode == 429) {
          message ??= 'Gaty köp synanyşyk. Birneme garaşyň.';
        } else if (resp.statusCode == 500) {
          message ??= 'Serwer näsazlygy (500). Täzeden synanyşyň.';
        } else if (resp.statusCode == 503) {
          message ??= 'Hyzmat wagtlaýyn elýeterli däl (503).';
        } else if (message == null) {
          message = 'OTP ugratmak başa barmady (status ${resp.statusCode})';
        }
      } else {
        // Success but message missing -> synthesize user-friendly success message
        message ??= 'OTP ugradyldy';
      }
      return OtpSendResult(
        success: success,
        message: message,
        otpId: body['otpId']?.toString(),
        raw: body,
      );
    } catch (e) {
      return OtpSendResult(
        success: false,
        message: 'Aragatnaşyk ýalňyşlygy: $e',
      );
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
    final uri = Uri.parse('${ApiKey.checkOtpKey}?phone=$full&otp=$code');
    try {
      final started = DateTime.now();
      final resp = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[auth] verifyOtp status=${resp.statusCode} elapsed=${elapsedMs}ms size=${resp.body.length} bodyKeys=${body is Map ? (body.keys.toList()) : []} body=$body',
        );
      }
      final success = _isOtpVerifySuccess(body, resp.statusCode);
      if (success) {
        final access =
            body['accessToken']?.toString() ?? body['token']?.toString();
        final refresh = body['refreshToken']?.toString();
        if (access != null) {
          final session = AuthSession(
            phone: full,
            accessToken: access,
            refreshToken: refresh,
          );
          currentSession.value = session;
          _persistSession(session);
        }
        return OtpVerifyResult(
          success: true,
          accessToken: access,
          refreshToken: refresh,
          raw: body,
          message: body['message']?.toString(),
        );
      }
      String? message = body['message']?.toString();
      if (resp.statusCode == 401 || resp.statusCode == 406) {
        message ??= 'Nädogry OTP kody';
      } else if (resp.statusCode == 404) {
        message ??= 'OTP tapylmady. Täzeden sorap görüň.';
      } else if (resp.statusCode == 500) {
        message ??= 'Serwer näsazlygy (500). Soňrak synanyşyň.';
      } else if (message == null) {
        message = 'OTP tassyklamak şowsuz (status ${resp.statusCode})';
      }
      return OtpVerifyResult(success: false, raw: body, message: message);
    } catch (e) {
      return OtpVerifyResult(
        success: false,
        message: 'Aragatnaşyk ýalňyşlygy: $e',
      );
    }
  }

  Future<AuthSession?> refreshTokens() async {
    final refresh = _box.read('REFRESH_TOKEN');
    if (refresh is! String) return null;
    try {
      final resp = await _client.get(
        Uri.parse(ApiKey.refreshTokenKey),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refresh',
        },
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final body = jsonDecode(resp.body);
        final newAccess = body['accessToken']?.toString();
        if (newAccess != null && currentSession.value != null) {
          final updated = currentSession.value!.copyWith(
            accessToken: newAccess,
          );
          currentSession.value = updated;
          _persistSession(updated);
          return updated;
        }
      } else if (resp.statusCode == 406) {
        logout();
      }
    } catch (_) {}
    return null;
  }

  void logout() {
    currentSession.value = null;
    // Core auth tokens
    _box.remove('ACCESS_TOKEN');
    _box.remove('REFRESH_TOKEN');
    _box.remove('USER_PHONE');
    // User profile cached fields
    _box.remove('user_name');
    _box.remove('user_phone');
    _box.remove('user_location');
    _box.remove('USER_ID');
    // Session derived flags (extend here if more keys added later)
    // Notify interested controllers (profile, favorites, etc.) to reset if registered
    // We do not erase the entire storage to preserve unrelated preferences (theme, language)
    _notifyControllersOfLogout();
    // Clear image cache for privacy (prevents next user from seeing cached images)
    _clearImageCache();
  }

  void _notifyControllersOfLogout() {
    // Use Get.isRegistered to avoid creating new instances during logout.
    if (Get.isRegistered<ProfileController>()) {
      try {
        final pc = Get.find<ProfileController>();
        // Reset reactive fields without disposing controller (or dispose forcefully if desired)
        pc.profile.value = null;
        pc.name.value = '';
        pc.phone.value = '';
        pc.location.value = ProfileController.defaultLocation;
        pc.nameController.clear();
        pc.locationController.text = ProfileController.defaultLocation;
        pc.hasLoadedProfile.value = false;
      } catch (_) {}
    }

    // Clear PostController cached data to prevent showing stale brand/model IDs
    if (Get.isRegistered<PostController>()) {
      try {
        final postCtrl = Get.find<PostController>();
        postCtrl.clearAllCachedData();
      } catch (_) {}
    }

    // Add other controllers reset logic here (favorites, etc.) when needed.
  }

  /// Clear all cached images on logout for privacy
  /// Runs asynchronously to avoid blocking the logout flow
  void _clearImageCache() {
    // Run async without awaiting to prevent logout delay
    CachedImageHelper.clearAllCache()
        .then((_) {
          debugPrint('[AuthService] ✅ Image cache cleared after logout');
        })
        .catchError((error) {
          debugPrint('[AuthService] ⚠️ Error clearing image cache: $error');
        });
  }

  void _persistSession(AuthSession session) {
    _box.write('ACCESS_TOKEN', session.accessToken);
    if (session.refreshToken != null) {
      _box.write('REFRESH_TOKEN', session.refreshToken);
    }
    _box.write('USER_PHONE', session.phone);
  }

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
      if (body.isNotEmpty) return true; // fallback
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
