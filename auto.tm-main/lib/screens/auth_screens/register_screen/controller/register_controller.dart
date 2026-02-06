import 'dart:async';
import 'dart:io';

// Legacy RegisterRequest removed in favor of AuthService
import 'package:auto_tm/services/auth/auth_service.dart';
import 'package:auto_tm/services/auth/phone_formatter.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/services/notification_sevice/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/utils/logger.dart';

class RegisterPageController extends GetxController {
  final notificationService = Get.find<NotificationService>();
  final TextEditingController phoneController = TextEditingController();
  final FocusNode phoneFocus = FocusNode();
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocus = FocusNode();
  // Reactive OTP input mirror for UI (TextEditingController.text isn't reactive)
  final RxString otpValue = ''.obs;

  // late String? token;
  final isLoading = false.obs;
  final storage = GetStorage();

  // Route the user was on before opening the register (number input) screen.
  // Used to return there after successful OTP without forcing profile edit.
  String? _originRoute;

  @override
  void onInit() {
    super.onInit();
    // Capture the route we came from (might be empty if root or pushed anonymously)
    _originRoute = Get.previousRoute.isNotEmpty ? Get.previousRoute : null;
  }

  Future<void> registerNewUser() async {
    // For phone-only auth, registration == requesting OTP.
    await requestOtp(navigateToOtp: true);
  }

  Future<void> requestOtp({bool navigateToOtp = false}) async {
    final sub = phoneController.text.trim();
    if (!PhoneFormatter.isValidSubscriber(sub)) {
      Get.snackbar('Nädogry', 'Telefon belgi formaty ýalňyş');
      return;
    }
    try {
      isLoading.value = true;
      final result = await AuthService.to.sendOtp(sub);
      if (result.success) {
        if (navigateToOtp) {
          Get.toNamed('/checkOtp');
        } else {
          Get.snackbar('Ugratdyk', 'OTP kody ugradyldy');
        }
      } else {
        Get.snackbar(
          'Ýalňyşlyk',
          result.message ?? 'OTP ugratmak başa barmady',
        );
      }
    } on SocketException {
      Get.defaultDialog(
        title: 'Aragatnaşyk ýitdi',
        middleText:
            'Internet baglanyşygynda mesele ýüze çykdy. Baglanyşygyňyzy barlaň.',
        confirm: ElevatedButton(
          onPressed: () => NavigationUtils.closeGlobal(),
          child: const Text('OK'),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies the OTP and then returns to the caller instead of forcing
  /// navigation to an Edit Profile screen. The invoking screen can decide
  /// what to do next (e.g., show a toast, refresh state, open edit later).
  /// Optionally provide [onVerified] to hook into success.
  Future<void> checkOtp({VoidCallback? onVerified}) async {
    if (isLoading.value) return; // guard against double taps
    final sub = phoneController.text.trim();
    final code = otpValue.value.trim();
    if (!PhoneFormatter.isValidSubscriber(sub)) {
      Get.snackbar('Nädogry', 'Telefon belgi formaty ýalňyş');
      return;
    }
    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
      Get.snackbar('Nädogry', 'OTP 5 sany san bolmaly');
      return;
    }
    try {
      isLoading.value = true;
      final result = await AuthService.to.verifyOtp(sub, code);
      if (result.success) {
        // Tokens are persisted by AuthService via TokenStore.
        // Fire-and-forget device token registration to avoid blocking navigation
        unawaited(_registerDeviceToken());
        notificationService.enableNotifications();
        final profileController = ProfileController.ensure();
        // Kick off fetch if not already running from onInit
        if (!profileController.hasLoadedProfile.value &&
            !profileController.isFetchingProfile.value) {
          AppLogger.d('Starting profile fetch post-OTP');
          unawaited(profileController.fetchProfile());
        } else {
          AppLogger.d('Profile fetch already in progress or loaded');
        }
        // Wait briefly for initial load (or timeout) to avoid premature navigation to edit screen
        await profileController.waitForInitialLoad();
        storage.write('user_phone', sub); // store subscriber only
        // Ensure default location persisted for brand new users
        final existingLoc = storage.read('user_location');
        if (existingLoc == null ||
            (existingLoc is String && existingLoc.isEmpty)) {
          storage.write('user_location', ProfileController.defaultLocation);
        }
        // Notify custom handler first
        if (onVerified != null) {
          onVerified();
        }
        if (!_suppressInternalNavigation) {
          // Strategy:
          // 1. Close OTP screen.
          // 2. Close Register (number input) screen.
          // 3. Prefer returning specifically to captured origin route if named.
          try {
            int popAttempts = 0;
            while (popAttempts < 2 && Get.key.currentState?.canPop() == true) {
              NavigationUtils.closeGlobal();
              popAttempts++;
            }
            // If we have a stored origin route name and we're not there yet, try to unwind further until matched.
            if (_originRoute != null && _originRoute!.isNotEmpty) {
              bool matched = false;
              Get.until((route) {
                final hit = route.settings.name == _originRoute;
                if (hit) matched = true;
                return hit;
              });
              if (!matched) {
                // Could not match by name (perhaps anonymous routes). Fallback to navView if stack shallow.
                if (Get.key.currentState?.canPop() != true) {
                  Get.offAllNamed('/navView');
                }
              }
            } else {
              // No named origin captured. If nothing left to pop, ensure user lands somewhere valid.
              if (Get.key.currentState?.canPop() != true) {
                Get.offAllNamed('/navView');
              }
            }
          } catch (_) {
            // Safe fallback in case of any routing irregularities
            Get.offAllNamed('/navView');
          }
        }
      } else {
        Get.snackbar('Şowsuz', result.message ?? 'Registrasiýa başa barmady');
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool _suppressInternalNavigation = false;
  // Public API for external flows wanting control over navigation.
  Future<bool> verifyExternally() async {
    _suppressInternalNavigation = true;
    final previousSession = AuthService.to.currentSession.value;
    await checkOtp();
    _suppressInternalNavigation = false;
    // Success if session was created or updated with access token
    return AuthService.to.currentSession.value != previousSession &&
        AuthService.to.currentSession.value?.accessToken.isNotEmpty == true;
  }

  Future<String?> _getFirebaseToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      // Add a timeout so we don't hang for >5s if FIS service is unavailable
      final token = await _getFirebaseToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (token != null) {
        notificationService.sendTokenToBackend(token);
      }
    } catch (_) {
      // swallow errors silently; not critical for login flow
    }
  }

  void unFocus() {
    phoneFocus.unfocus();
    otpFocus.unfocus();
  }

  var isChecked = false.obs;
  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
    if (phoneFocus.hasFocus) {
      phoneFocus.unfocus();
    }
  }

  // Back button functionality
  void goBack() {
    // Clear any focus
    unFocus();

    // Navigate back to the previous screen
    NavigationUtils.closeGlobal();
  }
}
