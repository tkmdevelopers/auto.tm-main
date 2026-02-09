import 'dart:async';

import 'package:auto_tm/screens/post_screen/controller/phone_verification_controller.dart';
import 'package:auto_tm/services/auth/auth_service.dart';
import 'package:auto_tm/services/auth/phone_formatter.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/services/notification_service/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:get_storage/get_storage.dart';

class RegisterPageController extends GetxController {
  final notificationService = Get.find<NotificationService>();
  final PhoneVerificationController phoneVerifyController = Get.find<PhoneVerificationController>();

  // Use the controllers from PhoneVerificationController to maintain a single source of truth
  TextEditingController get phoneController => phoneVerifyController.phoneController;
  TextEditingController get otpController => phoneVerifyController.otpController;
  
  final FocusNode phoneFocus = FocusNode();
  FocusNode get otpFocus => phoneVerifyController.otpFocus;

  // Restore otpValue for test compatibility and UI ease
  final RxString otpValue = ''.obs;

  final isLoading = false.obs;
  final storage = GetStorage();

  String? _originRoute;

  @override
  void onInit() {
    super.onInit();
    _originRoute = Get.previousRoute.isNotEmpty ? Get.previousRoute : null;
    
    // Sync otpController text to otpValue for reactivity
    otpController.addListener(() {
      otpValue.value = otpController.text;
    });
  }

  Future<void> registerNewUser() async {
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
      await phoneVerifyController.sendOtp();
      
      if (phoneVerifyController.needsOtp.value) {
        if (navigateToOtp) {
          Get.toNamed('/checkOtp');
        }
      }
    } catch (e) {
      Get.snackbar('Ýalňyşlyk', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkOtp({VoidCallback? onVerified}) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      
      await phoneVerifyController.verifyOtp();
      
      if (phoneVerifyController.isPhoneVerified.value) {
        final sub = phoneController.text.trim();
        
        unawaited(_registerDeviceToken());
        notificationService.enableNotifications();
        
        final profileController = ProfileController.ensure();
        if (!profileController.hasLoadedProfile.value &&
            !profileController.isFetchingProfile.value) {
          unawaited(profileController.fetchProfile());
        }
        
        await profileController.waitForInitialLoad();
        storage.write('user_phone', sub);
        
        final existingLoc = storage.read('user_location');
        if (existingLoc == null || (existingLoc is String && existingLoc.isEmpty)) {
          storage.write('user_location', ProfileController.defaultLocation);
        }

        if (onVerified != null) onVerified();
        
        if (!_suppressInternalNavigation) {
          _handlePostAuthNavigation();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePostAuthNavigation() {
    try {
      int popAttempts = 0;
      while (popAttempts < 2 && Get.key.currentState?.canPop() == true) {
        NavigationUtils.closeGlobal();
        popAttempts++;
      }
      if (_originRoute != null && _originRoute!.isNotEmpty) {
        bool matched = false;
        Get.until((route) {
          final hit = route.settings.name == _originRoute;
          if (hit) matched = true;
          return hit;
        });
        if (!matched && Get.key.currentState?.canPop() != true) {
          Get.offAllNamed('/navView');
        }
      } else if (Get.key.currentState?.canPop() != true) {
        Get.offAllNamed('/navView');
      }
    } catch (_) {
      Get.offAllNamed('/navView');
    }
  }

  bool _suppressInternalNavigation = false;
  Future<bool> verifyExternally() async {
    _suppressInternalNavigation = true;
    final previousSession = AuthService.to.currentSession.value;
    await checkOtp();
    _suppressInternalNavigation = false;
    return AuthService.to.currentSession.value != previousSession &&
        AuthService.to.currentSession.value?.accessToken.isNotEmpty == true;
  }

  Future<String?> _getFirebaseToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await _getFirebaseToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (token != null) {
        notificationService.sendTokenToBackend(token);
      }
    } catch (_) {}
  }

  void unFocus() {
    phoneFocus.unfocus();
    phoneVerifyController.otpFocus.unfocus();
  }

  var isChecked = false.obs;
  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
    if (phoneFocus.hasFocus) {
      phoneFocus.unfocus();
    }
  }

  void goBack() {
    unFocus();
    NavigationUtils.closeGlobal();
  }

  @override
  void onClose() {
    phoneFocus.dispose();
    super.onClose();
  }
}