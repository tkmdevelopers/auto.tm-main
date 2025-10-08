import 'package:auto_tm/screens/post_screen/posted_posts_screen.dart';
import 'package:auto_tm/services/token_service/token_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostCheckPage extends StatefulWidget {
  const PostCheckPage({super.key});

  @override
  State<PostCheckPage> createState() => _PostCheckPageState();
}

class _PostCheckPageState extends State<PostCheckPage> {
  late final TokenService tokenService;
  String? _token;

  @override
  void initState() {
    super.initState();
    tokenService = Get.put(TokenService());
    _token = tokenService.getToken();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = _token; // local snapshot; token changes only after login flow
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: token == null || token.isEmpty
          ? Center(
              child: TextButton(
                onPressed: () => Get.toNamed('/register'),
                child: Text('register or login to continue'.tr),
              ),
            )
          : PostedPostsScreen(),
    );
  }
}
