import 'package:auto_tm/screens/profile_screen/profile_screen.dart';
import 'package:auto_tm/services/token_service/token_service.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCheckPage extends StatelessWidget {
  ProfileCheckPage({super.key});

  final tokenService = Get.put(TokenService());

  @override
  Widget build(BuildContext context) {
    // final token = tokenService.getToken();
    // if (token == null || token.isEmpty) {
    //   Future.delayed(Duration.zero, () => Get.toNamed('/register'));
    // } else {
    //   // Future.delayed(Duration.zero, () => Get.offNamed('/home'));
    //   Future.delayed(Duration.zero, () => Get.off(() => PostedPostsScreen()));
    // }

    // Loading screen while checking token
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(
        () {
          final token = tokenService.getToken().obs;
// final isLoading = true.obs;
// if(isLoading.value) {
// return Center(
//           child: CircularProgressIndicator.adaptive(
//             backgroundColor: AppColors.primaryColor,
//             valueColor: AlwaysStoppedAnimation(AppColors.scaffoldColor),
//           ),
//         );
// }  
          if (token.value == null || token.value == '') {
            // isLoading.value = false;
            return Center(
              child: TextButton(
                  onPressed: () {
                    Get.toNamed('/register');
                  },
                  child: Text('register or login to continue'.tr)),
            );
            // return SRegisterPage();
          }
          // isLoading.value = false;
          if (token.value != null || token.value != '') {
            return ProfileScreen();
          }
          return Center(
            child: CircularProgressIndicator.adaptive(
              backgroundColor: AppColors.primaryColor,
              valueColor: AlwaysStoppedAnimation(AppColors.scaffoldColor),
            ),
          );
        },
      ),
    );
  }
}
