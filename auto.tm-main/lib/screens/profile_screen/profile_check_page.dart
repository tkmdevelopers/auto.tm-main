import 'package:auto_tm/screens/profile_screen/profile_screen.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCheckPage extends StatelessWidget {
  ProfileCheckPage({super.key});

  final Future<bool> _hasTokens = TokenStore.to.hasTokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<bool>(
        future: _hasTokens,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: AppColors.primaryColor,
                valueColor: AlwaysStoppedAnimation(AppColors.scaffoldColor),
              ),
            );
          }
          final hasTokens = snapshot.data == true;
          if (!hasTokens) {
            return Center(
              child: TextButton(
                onPressed: () => Get.toNamed('/register'),
                child: Text('register or login to continue'.tr),
              ),
            );
          }
          return ProfileScreen();
        },
      ),
    );
  }
}
