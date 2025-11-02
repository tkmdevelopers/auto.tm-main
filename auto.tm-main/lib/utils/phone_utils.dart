/// Phone number validation and formatting utilities for Turkmenistan phone numbers.
///
/// Turkmenistan phone numbers follow the format: +993 XX XXX XXX
/// - Country code: +993
/// - Subscriber number: 8 digits starting with 6 or 7
class PhoneUtils {
  // Subscriber number must start with 6 or 7 and be 8 digits
  static final RegExp _subscriberPattern = RegExp(r'^[67]\d{7}$');

  // Full phone number with country code (993 + 8 digits)
  static final RegExp _fullDigitsPattern = RegExp(r'^993[67]\d{7}$');

  /// Builds full phone number with country code from user input.
  ///
  /// Extracts digits from input and prefixes with '993' (Turkmenistan country code).
  /// Returns empty string if no digits found.
  ///
  /// Example:
  /// ```dart
  /// buildFullPhoneDigits('61234567') // Returns '99361234567'
  /// buildFullPhoneDigits('6 123 45 67') // Returns '99361234567'
  /// ```
  static String buildFullPhoneDigits(String input) {
    final sub = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (sub.isEmpty) return '';
    return '993$sub';
  }

  /// Validates Turkmenistan phone number input.
  ///
  /// Returns error message string if invalid, null if valid.
  ///
  /// Validation rules:
  /// - Must have 8 digits
  /// - Must start with 6 or 7
  /// - Full number (993 + digits) must match expected pattern
  ///
  /// Example:
  /// ```dart
  /// validatePhoneInput('61234567') // Returns null (valid)
  /// validatePhoneInput('51234567') // Returns 'Must start with 6 or 7'
  /// validatePhoneInput('612345') // Returns 'Enter 8 digits (e.g. 6XXXXXXX)'
  /// ```
  static String? validatePhoneInput(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return 'Phone number required';
    }

    if (digits.length != 8) {
      return 'Enter 8 digits (e.g. 6XXXXXXX)';
    }

    if (!_subscriberPattern.hasMatch(digits)) {
      if (!RegExp(r'^[67]').hasMatch(digits)) {
        return 'Must start with 6 or 7';
      }
      return 'Invalid phone digits';
    }

    if (!_fullDigitsPattern.hasMatch('993$digits')) {
      return 'Invalid full phone';
    }

    return null; // Valid
  }

  /// Formats phone number for display with spaces.
  ///
  /// Example:
  /// ```dart
  /// formatForDisplay('99361234567') // Returns '+993 61 234 567'
  /// formatForDisplay('61234567') // Returns '61 234 567'
  /// ```
  static String formatForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length >= 11 && digits.startsWith('993')) {
      // Full international format: +993 XX XXX XXX
      final sub = digits.substring(3);
      if (sub.length == 8) {
        return '+993 ${sub.substring(0, 2)} ${sub.substring(2, 5)} ${sub.substring(5)}';
      }
    }

    if (digits.length == 8) {
      // Subscriber format: XX XXX XXX
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }

    return phone; // Return as-is if doesn't match expected format
  }

  /// Checks if a phone number is valid (for Turkmenistan).
  static bool isValidPhone(String input) {
    return validatePhoneInput(input) == null;
  }

  /// Removes leading '+' from a phone number string.
  ///
  /// Example:
  /// ```dart
  /// stripPlus('+99361234567') // Returns '99361234567'
  /// stripPlus('99361234567') // Returns '99361234567'
  /// ```
  static String stripPlus(String value) {
    return value.startsWith('+') ? value.substring(1) : value;
  }

  /// Extracts 8-digit subscriber number from full phone number.
  ///
  /// Handles both international format (+993XXXXXXXX) and local format.
  ///
  /// Example:
  /// ```dart
  /// extractSubscriber('+99361234567') // Returns '61234567'
  /// extractSubscriber('99361234567') // Returns '61234567'
  /// extractSubscriber('61234567') // Returns '61234567'
  /// ```
  static String extractSubscriber(String full) {
    final digits = full.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('993') && digits.length >= 11) {
      return digits.substring(3);
    }
    return digits;
  }
}
