import 'package:auto_tm/screens/post_screen/posted_posts_screen.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostCheckPage extends StatefulWidget {
  const PostCheckPage({super.key});

  @override
  State<PostCheckPage> createState() => _PostCheckPageState();
}

class _PostCheckPageState extends State<PostCheckPage> {
  late final Future<bool> _hasTokens;

  @override
  void initState() {
    super.initState();
    _hasTokens = TokenStore.to.hasTokens;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<bool>(
        future: _hasTokens,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
          return PostedPostsScreen();
        },
      ),
    );
  }
}
