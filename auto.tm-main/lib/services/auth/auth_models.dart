import 'package:flutter/foundation.dart';

@immutable
class OtpSendResult {
  final bool success;
  final String? message;
  final String? otpId; // if backend supplies an identifier
  final Map<String, dynamic>? raw;
  const OtpSendResult({
    required this.success,
    this.message,
    this.otpId,
    this.raw,
  });
}

@immutable
class OtpVerifyResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? raw;
  final String? message;
  const OtpVerifyResult({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.raw,
    this.message,
  });
}

@immutable
class AuthSession {
  final String phone; // full digits without + (e.g. 9936xxxxxxx)
  final String accessToken;
  final String? refreshToken;
  const AuthSession({
    required this.phone,
    required this.accessToken,
    this.refreshToken,
  });

  AuthSession copyWith({String? accessToken, String? refreshToken}) =>
      AuthSession(
        phone: phone,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
      );
}
