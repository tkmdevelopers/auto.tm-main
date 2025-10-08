// Deprecated legacy request class retained temporarily for compatibility.
// Will be removed after all controllers migrate to AuthService.
import 'dart:convert';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RegisterRequest {
  static Future<Map<String, dynamic>?> registerUser(String phone) async {
    final apiUrl = ApiKey.registerKey;
    final Map<String, dynamic> requestdata = {'phone': phone};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestdata),
      );
      if (response.statusCode == 200 || response.statusCode == 500) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      Get.defaultDialog(
        title: 'Error',
        middleText: 'Error in registerUser: $e',
      );
      return null;
    }
  }

  static Future<Map<String, dynamic>?> receiveOtp(String phone) async {
    final apiUrl = "${ApiKey.sendOtpKey}?phone=$phone";
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      Get.defaultDialog(title: 'Error', middleText: 'Error in receiveOtp: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendCheckOtp(
    String phone,
    String otp,
  ) async {
    final apiUrl = "${ApiKey.checkOtpKey}?phone=$phone&otp=$otp";
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      Get.defaultDialog(
        title: 'Error',
        middleText: 'Error in sendCheckOtp: $e',
      );
      return null;
    }
  }
}
