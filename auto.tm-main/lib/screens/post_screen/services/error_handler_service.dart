import 'package:get/get.dart';
import '../repository/repository_exceptions.dart';

/// Centralized error handling service for consistent user-facing error messages.
///
/// Provides methods for displaying errors, success messages, and handling
/// common API/authentication errors with localized messages.
class ErrorHandlerService {
  /// Show error snackbar with standardized styling
  static void showError(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Error'.tr,
      message.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show success snackbar with standardized styling
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Success'.tr,
      message.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show info snackbar with standardized styling
  static void showInfo(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Info'.tr,
      message.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show validation error snackbar
  static void showValidationError(String message) {
    Get.snackbar('Invalid'.tr, message.tr, snackPosition: SnackPosition.BOTTOM);
  }

  /// Handle authentication expired error
  static void handleAuthExpired() {
    showError('Session expired. Please login again.');
  }

  /// Handle repository exceptions with user-friendly messages
  static void handleRepositoryError(Exception e, {String? context}) {
    if (e is AuthExpiredException) {
      handleAuthExpired();
    } else if (e is HttpException) {
      final contextMsg = context != null ? '$context: ' : '';
      showError('${contextMsg}${e.message}');
    } else {
      final contextMsg = context != null ? '$context: ' : '';
      showError('${contextMsg}${e.toString()}');
    }
  }

  /// Handle generic API errors
  static void handleApiError(dynamic error, {String? context}) {
    final contextMsg = context != null ? '$context: ' : '';

    if (error is Exception) {
      handleRepositoryError(error, context: context);
    } else if (error is String) {
      showError('$contextMsg$error');
    } else {
      showError('${contextMsg}An unexpected error occurred');
    }
  }

  /// Handle timeout errors
  static void handleTimeout() {
    showError('Request timed out. Please try again.');
  }

  /// Handle upload errors
  static String formatUploadError(String? error, {String? defaultMessage}) {
    return error ?? defaultMessage ?? 'Upload failed';
  }

  /// Handle image picker errors
  static void handleImagePickerError(dynamic e) {
    showError('Failed to pick images: $e');
  }

  /// Handle video picker errors
  static void handleVideoPickerError(dynamic e) {
    showError('Failed to pick video: $e');
  }

  /// Handle OTP errors
  static void handleOtpError(String? message) {
    showError(message ?? 'Failed to send OTP');
  }

  /// Handle phone validation errors
  static void handlePhoneValidationError(String error) {
    showError(error, title: 'Invalid phone');
  }

  /// Show OTP sent success message
  static void showOtpSent(String phone) {
    showSuccess('OTP has been sent to +$phone', title: 'OTP Sent');
  }

  /// Show phone verification success
  static void showPhoneVerified() {
    showSuccess('Phone verified successfully');
  }

  /// Handle OTP verification errors
  static void handleOtpVerificationError(String? message) {
    showError(message ?? 'Failed to verify OTP', title: 'Verification Failed');
  }

  /// Show invalid OTP format error
  static void showInvalidOtpFormat() {
    showError('OTP must be exactly 5 digits', title: 'Invalid');
  }

  /// Show OTP verification required error
  static void showOtpRequired() {
    showError('You have to go through OTP verification.');
  }

  /// Handle cancel cleanup errors (for internal logging, not user-facing)
  static String formatCancelError(dynamic e) {
    return 'Cancel cleanup error: $e';
  }
}
