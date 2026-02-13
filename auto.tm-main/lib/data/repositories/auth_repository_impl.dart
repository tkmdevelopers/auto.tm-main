import 'dart:convert';
import 'package:auto_tm/data/mappers/user_profile_mapper.dart';
import 'package:auto_tm/domain/models/auth_models.dart';
import 'package:auto_tm/domain/models/user_profile.dart';
import 'package:auto_tm/domain/repositories/auth_repository.dart';
import 'package:auto_tm/data/datasources/local/local_storage.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final LocalStorage _storage;

  AuthRepositoryImpl(this._apiClient, {LocalStorage? storage})
    : _storage = storage ?? GetStorageImpl();

  @override
  Future<OtpSendResult> sendOtp(String fullPhoneNumber) async {
    try {
      final resp = await _apiClient.dio.post(
        'otp/send',
        data: {'phone': fullPhoneNumber},
      );
      final body = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : <String, dynamic>{};

      final success = _isOtpSendSuccess(body, resp.statusCode ?? 0);
      return OtpSendResult(
        success: success,
        message: body['message']?.toString(),
        otpId: body['otpId']?.toString(),
        raw: body,
      );
    } catch (e) {
      return OtpSendResult(success: false, message: 'Exception: $e');
    }
  }

  @override
  Future<OtpVerifyResult> verifyOtp(String fullPhoneNumber, String code) async {
    try {
      final resp = await _apiClient.dio.post(
        'otp/verify',
        data: {'phone': fullPhoneNumber, 'otp': code},
      );
      final body = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : <String, dynamic>{};

      final success = _isOtpVerifySuccess(body, resp.statusCode ?? 0);
      if (success) {
        final access =
            body['accessToken']?.toString() ?? body['token']?.toString();
        final refresh = body['refreshToken']?.toString();
        return OtpVerifyResult(
          success: true,
          accessToken: access,
          refreshToken: refresh,
          raw: body,
          message: body['message']?.toString(),
        );
      }
      return OtpVerifyResult(
        success: false,
        raw: body,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return OtpVerifyResult(success: false, message: 'Exception: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('auth/logout');
    } catch (_) {
      // Best-effort
    }
  }

  @override
  Future<UserProfile?> getMe() async {
    final response = await _apiClient.dio.get('auth/me');
    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? Map<String, dynamic>.from(json.decode(raw))
          : Map<String, dynamic>.from(raw as Map);

      // Save to cache
      _storage.write('cached_profile_json', json.encode(data));

      return UserProfileMapper.fromJson(data);
    }
    return null;
  }

  @override
  Future<UserProfile?> getCachedMe() async {
    final cached = _storage.read<String>('cached_profile_json');
    if (cached == null || cached is! String || cached.isEmpty) {
      return null;
    }
    try {
      final data = json.decode(cached);
      if (data is! Map) return null;
      return UserProfileMapper.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateProfile({String? name, String? location}) async {
    final Map<String, dynamic> body = {
      if (name != null && name.isNotEmpty) 'name': name,
      'location': ?location,
    };
    final response = await _apiClient.dio.put('auth', data: body);
    return response.statusCode == 200;
  }

  @override
  Future<String?> updateAvatar(Uint8List imageBytes) async {
    try {
      final profile = await getMe();
      if (profile == null) return null;

      final formData = FormData.fromMap({
        'uuid': profile.uuid,
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _apiClient.dio.put('photo/user', data: formData);

      if (response.statusCode == 200 && response.data != null) {
        final jsonBody = response.data;
        final paths = jsonBody['paths'];
        if (paths is Map) {
          return paths['medium']?.toString() ??
              paths['large']?.toString() ??
              paths['small']?.toString();
        }
      }
    } catch (_) {}
    return null;
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
      if (body.isNotEmpty) return true;
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
