import 'dart:typed_data';
import 'package:auto_tm/domain/models/auth_models.dart';
import 'package:auto_tm/domain/models/user_profile.dart';

abstract class AuthRepository {
  Future<OtpSendResult> sendOtp(String fullPhoneNumber);
  Future<OtpVerifyResult> verifyOtp(String fullPhoneNumber, String code);
  Future<void> logout();
  Future<UserProfile?> getMe();
  Future<UserProfile?> getCachedMe();
  Future<bool> updateProfile({String? name, String? location});
  Future<String?> updateAvatar(Uint8List imageBytes);
}
