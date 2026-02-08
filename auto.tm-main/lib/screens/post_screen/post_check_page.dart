import 'package:auto_tm/screens/post_screen/posted_posts_screen.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostCheckPage extends StatelessWidget {
  const PostCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (TokenStore.to.isLoggedIn.value) {
          return PostedPostsScreen();
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
