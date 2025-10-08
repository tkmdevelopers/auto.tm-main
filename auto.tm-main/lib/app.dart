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
    if (token == null || token.isEmpty) {
      Future.delayed(Duration.zero, () => Get.offNamed('/register'));
    } else {
      // Future.delayed(Duration.zero, () => Get.offNamed('/home'));
      Future.delayed(Duration.zero, () => Get.offNamed('/navView'));
    }

    // Loading screen while checking token
    return const Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      body: Center(
        child: CircularProgressIndicator.adaptive(
          backgroundColor: AppColors.primaryColor,
          valueColor: AlwaysStoppedAnimation(AppColors.scaffoldColor),
        ),
      ),
    );
  }
}
