import 'package:auto_tm/services/token_service/token_service.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthCheckPage extends StatelessWidget {
  AuthCheckPage({super.key});

  final tokenService = Get.put(TokenService());

  @override
  Widget build(BuildContext context) {
    final token = tokenService.getToken();

    // Immediate navigation without delay to avoid flash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (token == null || token.isEmpty) {
        Get.offNamed('/register');
      } else {
        Get.offNamed('/navView');
      }
    });

    // Minimal invisible scaffold - user won't see this
    // Keep it simple to minimize flash during logout
    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      body: const SizedBox.shrink(), // Empty - navigation happens immediately
    );
  }
}
