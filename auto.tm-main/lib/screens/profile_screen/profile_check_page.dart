import 'package:auto_tm/screens/profile_screen/profile_screen.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCheckPage extends StatelessWidget {
  const ProfileCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (TokenStore.to.isLoggedIn.value) {
          return ProfileScreen();
        }
        return Center(
          child: TextButton(
            onPressed: () => Get.toNamed('/register'),
            child: Text('register or login to continue'.tr),
          ),
        );
      }),
    );
  }
}
