import 'dart:convert';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RegisterRequest {
  static Future<Map<String, dynamic>?> registerUser(String phone) async {
    // final apiUrl = "${ApiKey.sendOtpKey}?phoneNumber=993$phone";
    final apiUrl = ApiKey.registerKey;

    final Map<String, dynamic> requestdata = {'phone': phone};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: json.encode(requestdata),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else if (response.statusCode == 500) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return null;
      }
    } catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in sendOtp: ${e.toString()}",
      );
      return null; // Return null in case of an error
    }
  }

  static Future<Map<String, dynamic>?> receiveOtp(String phone) async {
    final apiUrl = "${ApiKey.sendOtpKey}?phone=$phone";
    // const apiUrl = ApiKey.sendOtpKey;

    // final Map<String, dynamic> requestdata = {
    //   'phone': phone,
    // };

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        // body: json.encode(requestdata),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return null;
      }
    } catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in sendOtp: ${e.toString()}",
      );
      return null; // Return null in case of an error
    }
  }

  static Future<Map<String, dynamic>?> sendCheckOtp(
    String phone,
    String otp,
  ) async {
    final apiUrl = "${ApiKey.checkOtpKey}?phone=$phone&otp=$otp";

    // final Map<String, dynamic> requestdata = {
    //   'phone': phone,
    //   'password': otp,
    // };

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        // body: json.encode(requestdata),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData; // Return the parsed JSON response
      } else {
        return null; // Return null if the response is not successful
      }
    } catch (e) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Error in checkOtp: ${e.toString()}",
      );
      return null; // Return null in case of an error
    }
  }
}
