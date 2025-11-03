/// Centralized user-facing error & status messages.
/// Map short codes to localized or human-readable strings to ensure consistency.
class ErrorMessages {
  static const Map<String, String> _map = {
    // Auth / token
    'no_token': 'No access token found. Please log in again.',
    'token_refresh_fail':
        'Failed to refresh access token. Please log in again.',
    'otp_invalid_format': 'Telefon belgi formaty ýalňyş',
    'otp_invalid_code': 'OTP 5 sany san bolmaly',
    'otp_failed': 'Registrasiýa başa barmady',

    // Profile
    'profile_empty_body': 'Empty response from server',
    'profile_parse_fail': 'Failed to parse profile data.',
    'profile_fetch_fail': 'Failed to fetch profile.',
    'profile_timeout': 'Profile request took too long. Pull to retry.',

    // Upload / image
    'image_upload_timeout': 'Image upload took too long. Please try again.',
    'image_upload_fail': 'Failed to upload image.',

    // Generic
    'unexpected_error': 'An unexpected error occurred.',
  };

  static String resolve(String code, {String? details}) {
    final base = _map[code] ?? code;
    if (details != null && details.isNotEmpty) {
      return '$base $details';
    }
    return base;
  }
}
