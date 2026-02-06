import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Auth check page shown at `/`.
///
/// Instead of just checking whether a token exists (which could be expired),
/// we actually validate the session by calling `GET /auth/me`.
/// If the access token is expired, the Dio interceptor will attempt a
/// transparent refresh. If everything fails, the user is routed to `/register`.
class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  Future<void> _validateSession() async {
    final hasTokens = await TokenStore.to.hasTokens;
    if (!hasTokens) {
      Get.offAllNamed('/register');
      return;
    }

    try {
      // The ApiClient interceptor will auto-refresh if the access token is expired.
      final response = await ApiClient.to.dio.get('auth/me');
      if (response.statusCode == 200) {
        Get.offAllNamed('/navView');
        return;
      }
    } catch (_) {
      // If /auth/me fails even after interceptor refresh, session is dead.
    }

    // Fallback: session invalid → login
    await TokenStore.to.clearAll();
    Get.offAllNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
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
