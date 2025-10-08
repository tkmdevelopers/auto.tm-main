class PhoneFormatter {
  static final RegExp _subscriberPattern = RegExp(r'^[67]\d{7}$');
  static final RegExp _fullDigitsPattern = RegExp(r'^993[67]\d{7}$');

  static bool isValidSubscriber(String input) =>
      _subscriberPattern.hasMatch(input);
  static String buildFullDigits(String subscriber) => '993$subscriber';
  static bool isValidFull(String fullDigits) =>
      _fullDigitsPattern.hasMatch(fullDigits);

  static String extractSubscriber(String anyPhone) {
    final digits = anyPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('993') && digits.length >= 11) {
      return digits.substring(3);
    }
    return digits;
  }
}
