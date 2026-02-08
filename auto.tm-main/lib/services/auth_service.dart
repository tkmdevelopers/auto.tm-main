import 'dart:convert';
import 'package:get/get.dart';
import 'package:dio/dio.dart'; // Import Dio for DioException handling
import 'package:auto_tm/services/network/api_client.dart'; // Correct ApiClient import
import 'package:auto_tm/utils/key.dart'; // For ApiKey

class AuthService extends GetxService {
  final ApiClient _apiClient;

  AuthService(this._apiClient); // Constructor injection for ApiClient

  Future<Map<String, dynamic>?> registerUser(String phone) async {
    final apiUrl = ApiKey.registerKey;
    final Map<String, dynamic> requestData = {'phone': phone};

    try {
      final response = await _apiClient.dio.post(
        apiUrl,
        data: json.encode(requestData),
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 500) {
        return response.data as Map<String, dynamic>;
      } else {
        return null;
      }
    } on DioException catch (e) { // Catch DioException instead of generic Exception
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in registerUser: ${e.message ?? e.toString()}",
      );
      return null;
    } catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in registerUser: ${e.toString()}",
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> receiveOtp(String phone) async {
    final apiUrl = "${ApiKey.sendOtpKey}?phone=$phone";

    try {
      final response = await _apiClient.dio.get(
        apiUrl,
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        return null;
      }
    } on DioException catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in receiveOtp: ${e.message ?? e.toString()}",
      );
      return null;
    } catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in receiveOtp: ${e.toString()}",
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendCheckOtp(
    String phone,
    String otp,
  ) async {
    final apiUrl = "${ApiKey.checkOtpKey}?phone=$phone&otp=$otp";

    try {
      final response = await _apiClient.dio.get(
        apiUrl,
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return null;
      }
    } on DioException catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in sendCheckOtp: ${e.message ?? e.toString()}",
      );
      return null;
    } catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in sendCheckOtp: ${e.toString()}",
      );
      return null;
    }
  }
}
