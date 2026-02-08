import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/services/auth/auth_service.dart';

/// Manages phone verification (OTP) flow.
///
/// Extracted from PostController to follow single-responsibility principle.
/// Can be reused in any screen that needs phone verification.
class PhoneVerificationController extends GetxController {
  // ---- Text controllers & focus ----
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocus = FocusNode();

  // ---- Observable state ----
  final RxBool isPhoneVerified = false.obs;
  final RxBool isOriginalPhone = true.obs;
  final RxBool needsOtp = false.obs;
  final RxBool showOtpField = false.obs;
  final RxBool isSendingOtp = false.obs;
  final RxBool isLoadingOtp = false.obs;
  final RxBool canResend = true.obs;
  final RxInt countdown = 0.obs;
  final RxInt resendCountdown = 0.obs;

  // ---- Internal state ----
  /// Canonical phone from the user profile in +993XXXXXXXX format.
  String _originalFullPhone = '';
  Timer? _timer;

  /// Optional callback when a field changes (for dirty tracking in parent).
  VoidCallback? onFieldChanged;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _initializeOriginalPhone();
    _attachProfilePhoneListener();
    phoneController.addListener(_onPhoneInputChanged);
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.removeListener(_onPhoneInputChanged);
    phoneController.dispose();
    otpController.dispose();
    otpFocus.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Build the full phone number with +993 prefix, suitable for API calls.
  String get fullPhoneNumber => '+${_buildFullPhoneDigits()}';

  /// Whether the user has modified the phone field from the original profile phone.
  bool get hasModifiedPhone {
    final current = phoneController.text.trim();
    if (current.isEmpty) return false;
    if (_originalFullPhone.isEmpty) return true;
    return _stripPlus(_originalFullPhone) != _buildFullPhoneDigits();
  }

  /// Send an OTP to the entered phone number.
  Future<void> sendOtp() async {
    isSendingOtp.value = true;
    try {
      final validationError = _validatePhoneInput();
      if (validationError != null) {
        Get.snackbar('Invalid phone', validationError);
        return;
      }
      final otpPhone = _buildFullPhoneDigits();
      if (_originalFullPhone.isNotEmpty &&
          _stripPlus(_originalFullPhone) == otpPhone) {
        // Original trusted phone: no OTP required
        isPhoneVerified.value = true;
        needsOtp.value = false;
        showOtpField.value = false;
        return;
      }
      final subscriber = otpPhone.substring(3);
      final result = await AuthService.to.sendOtp(subscriber);
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[otp][post] send via AuthService success=${result.success} raw=${result.raw}',
        );
      }
      if (result.success) {
        showOtpField.value = true;
        needsOtp.value = true;
        _startCountdown();
        Get.snackbar('OTP Sent', 'OTP has been sent to +$otpPhone');
      } else {
        Get.snackbar('Error', result.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      Get.snackbar('Exception', 'Failed to send OTP: $e');
    } finally {
      isSendingOtp.value = false;
    }
  }

  /// Verify the entered OTP code.
  Future<void> verifyOtp() async {
    final phoneError = _validatePhoneInput();
    if (phoneError != null) {
      Get.snackbar('Invalid phone', phoneError);
      return;
    }
    final otp = otpController.text.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(otp)) {
      Get.snackbar('Invalid', 'OTP must be exactly 5 digits');
      return;
    }
    final otpPhone = _buildFullPhoneDigits();
    try {
      final subscriber = otpPhone.substring(3);
      final result = await AuthService.to.verifyOtp(subscriber, otp);
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[otp][post] verify via AuthService success=${result.success} raw=${result.raw}',
        );
      }
      if (result.success) {
        isPhoneVerified.value = true;
        needsOtp.value = false;
        showOtpField.value = false;
        _timer?.cancel();
        Get.snackbar('Success', 'Phone verified successfully');
      } else {
        Get.snackbar(
          'Invalid OTP',
          result.message ?? 'Please check the code and try again',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Error verifying OTP: $e');
    }
  }

  /// Reset phone verification state (e.g. when form is reset).
  void resetVerification() {
    if (_originalFullPhone.isNotEmpty) {
      final sub = _extractSubscriber(_originalFullPhone);
      phoneController.text = sub.length == 8 ? sub : '';
    } else {
      phoneController.clear();
    }
    otpController.clear();
    isPhoneVerified.value = true;
    needsOtp.value = false;
    showOtpField.value = false;
    isSendingOtp.value = false;
    countdown.value = 0;
  }

  /// Restore the original profile phone into the field and mark as verified.
  /// Used by form restore / load to ensure the original subscriber is shown.
  void restoreOriginalPhone() {
    if (_originalFullPhone.isNotEmpty) {
      final sub = _extractSubscriber(_originalFullPhone);
      if (sub.length == 8) phoneController.text = sub;
      isPhoneVerified.value = true;
      isOriginalPhone.value = true;
      needsOtp.value = false;
      showOtpField.value = false;
    } else {
      phoneController.text = '';
    }
  }

  // ---------------------------------------------------------------------------
  // Phone input change listener
  // ---------------------------------------------------------------------------

  void _onPhoneInputChanged() {
    onFieldChanged?.call();
    final sub = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final current = sub.isEmpty ? '' : '993$sub';
    if (sub.isEmpty) {
      isPhoneVerified.value = false;
      needsOtp.value = false;
      showOtpField.value = false;
      if (kDebugMode) {
        // ignore: avoid_print
        print('[phone] cleared -> reset verification flags');
      }
      return;
    }
    if (_originalFullPhone.isNotEmpty &&
        _stripPlus(_originalFullPhone) == current) {
      if (!isPhoneVerified.value) isPhoneVerified.value = true;
      needsOtp.value = false;
      showOtpField.value = false;
      _timer?.cancel();
      countdown.value = 0;
      otpController.clear();
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[phone] auto-verified using original full phone=$_originalFullPhone sub=$sub',
        );
      }
      return;
    }
    isPhoneVerified.value = false;
    needsOtp.value = true;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[phone] changed to new subscriber=$sub -> requires OTP');
    }
  }

  // ---------------------------------------------------------------------------
  // Countdown timer
  // ---------------------------------------------------------------------------

  void _startCountdown() {
    countdown.value = 60;
    canResend.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Phone helper utilities
  // ---------------------------------------------------------------------------

  static final RegExp _subscriberPattern = RegExp(r'^[67]\d{7}$');
  static final RegExp _fullDigitsPattern = RegExp(r'^993[67]\d{7}$');

  String _stripPlus(String v) => v.startsWith('+') ? v.substring(1) : v;

  String _extractSubscriber(String full) {
    final digits = full.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('993') && digits.length >= 11) {
      return digits.substring(3);
    }
    return digits;
  }

  String _buildFullPhoneDigits() {
    final sub = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (sub.isEmpty) return '';
    return '993$sub';
  }

  String? _validatePhoneInput() {
    final digits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Phone number required';
    if (digits.length != 8) return 'Enter 8 digits (e.g. 6XXXXXXX)';
    if (!_subscriberPattern.hasMatch(digits)) {
      if (!RegExp(r'^[67]').hasMatch(digits)) return 'Must start with 6 or 7';
      return 'Invalid phone digits';
    }
    if (!_fullDigitsPattern.hasMatch('993$digits')) return 'Invalid full phone';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Original phone initialization (from ProfileController)
  // ---------------------------------------------------------------------------

  void _initializeOriginalPhone() {
    try {
      String? candidate;
      if (Get.isRegistered<ProfileController>()) {
        final pc = Get.find<ProfileController>();
        if (pc.phone.value.isNotEmpty) candidate = pc.phone.value;
      }
      if (candidate == null || candidate.isEmpty) return;
      final normalized = _normalizeToFullPhone(candidate);
      if (normalized == null) return;
      _originalFullPhone = normalized;
      final sub = _extractSubscriber(_originalFullPhone);
      if (sub.length == 8 && phoneController.text.trim().isEmpty) {
        phoneController.text = sub;
      }
      isOriginalPhone.value = true;
      isPhoneVerified.value = true;
      needsOtp.value = false;
      showOtpField.value = false;
    } catch (_) {}
  }

  void _attachProfilePhoneListener() {
    if (!Get.isRegistered<ProfileController>()) return;
    final pc = Get.find<ProfileController>();
    if (_originalFullPhone.isEmpty && pc.phone.value.isNotEmpty) {
      final n = _normalizeToFullPhone(pc.phone.value);
      if (n != null) _adoptOriginalPhone(n);
    }
    ever<String>(pc.phone, (p) {
      if (_originalFullPhone.isNotEmpty) return;
      if (p.isEmpty) return;
      final n = _normalizeToFullPhone(p);
      if (n != null) _adoptOriginalPhone(n);
    });
  }

  void _adoptOriginalPhone(String fullPhone) {
    _originalFullPhone = fullPhone;
    final sub = _extractSubscriber(fullPhone);
    if (phoneController.text.trim().isEmpty && sub.length == 8) {
      phoneController.text = sub;
    }
    isOriginalPhone.value = true;
    isPhoneVerified.value = true;
    needsOtp.value = false;
    showOtpField.value = false;
  }

  String? _normalizeToFullPhone(String raw) {
    try {
      var cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
      if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
      if (RegExp(r'^[67]\d{7}$').hasMatch(cleaned)) {
        cleaned = '993$cleaned';
      }
      if (!cleaned.startsWith('993')) return null;
      if (cleaned.length < 11) return null;
      return '+$cleaned';
    } catch (_) {
      return null;
    }
  }
}
