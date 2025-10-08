// import 'package:auto_tm/screens/auth_screens/login_screen/controller/login_controller.dart';
// import 'package:auto_tm/screens/auth_screens/login_screen/widgets/main_button.dart';
// import 'package:auto_tm/screens/auth_screens/login_screen/widgets/text_field_text.dart';
// import 'package:auto_tm/ui_components/colors.dart';
// import 'package:auto_tm/ui_components/images.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';

// class SLoginPage extends StatelessWidget {
//   SLoginPage({super.key});

//   final LoginController getController = Get.put(LoginController());
//   // final AuthController authController = Get.put(AuthController());

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final height = mediaQuery.size.height;
//     final theme = Theme.of(context);

//     return GestureDetector(
//       onTap: () => getController.unFocus(),
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         backgroundColor: theme.scaffoldBackgroundColor,
//         body: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               // mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   height: height * 0.05,
//                 ),
//                 //! logo
//                 SvgPicture.asset(
//                   AppImages.appLogoSvg,
//                   height: height * 0.25,
//                   color: theme.colorScheme.primary,
//                 ),
//                 // Image(
//                 //   image: AssetImage(AppImages.appLogo),
//                 //   height: height * 0.25,
//                 //   color: theme.colorScheme.primary,
//                 // ),

//                 //? margin
//                 SizedBox(
//                   height: height * 0,
//                 ),

//                 //! welcomeback message
//                 Text(
//                   'Login'.tr,
//                   style: TextStyle(
//                     color: theme.colorScheme.primary,
//                     fontSize: 32,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),

//                 //? margin
//                 SizedBox(
//                   height: height * 0.05,
//                 ),

//                 Row(
//                   children: [
//                     Text(
//                       'Email'.tr,
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                         color: theme.colorScheme.primary,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),

//                 SizedBox(
//                   height: height * 0.01,
//                 ),

//                 //! phone textfield
//                 // Obx(
//                 // () =>
//                 STextField(
//                   isObscure: false,
//                   controller: getController.emailController,
//                   focusNode: getController.emailFocus,
//                   hintText: 'Email...'.tr,
//                   onSubmitted: (value) {
//                     getController.emailFocus.unfocus();
//                     getController.passwordFocus.requestFocus();
//                   },
//                 ),
//                 // ),

//                 SizedBox(
//                   height: height * 0.02,
//                 ),

//                 Row(
//                   children: [
//                     Text(
//                       'Password'.tr,
//                       style: TextStyle(
//                         color: theme.colorScheme.primary,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),

//                 SizedBox(
//                   height: height * 0.01,
//                 ),

//                 //! phone textfield
//                 // Obx(
//                 //   () =>
//                 STextField(
//                   isObscure: true,
//                   controller: getController.passowordController,
//                   focusNode: getController.passwordFocus,
//                   hintText: 'Password...'.tr,
//                 ),
//                 // ),

//                 SizedBox(
//                   height: height * 0.02,
//                 ),

//                 Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () {},
//                       child: Text(
//                         'Forgot your password?'.tr,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w400,
//                           color: AppColors.primaryColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 SizedBox(
//                   height: height * 0.02,
//                 ),

//                 //! login button
//                 // Obx(
//                 //   () =>
//                 SButton(
//                   title: "Submit",
//                   buttonColor: (getController.emailController.text.length >= 8)
//                       ? AppColors.primaryColor
//                       : AppColors.textSecondaryColor,
//                   onTap: (getController.emailController.text.length >= 8)
//                       ? () {
//                           // getController.requestOtp();
//                           getController.loginUser();
//                         }
//                       : () {
//                           // ("Ýalňyşlyk",
//                           //     "Gizlinlik syýasatyna razylyk bermeli we telefon nomerinizi girizmeli!");
//                         },
//                 ),
//                 // ),

//                 SizedBox(
//                   height: height * 0.01,
//                 ),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'New user? '.tr,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w400,
//                         color: theme.colorScheme.primary,
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: () => Get.offNamed('/register'),
//                       // onPressed: () {
//                       //   authController.toggleToRegister();
//                       // },
//                       child: Text(
//                         'Create one'.tr,
//                         style: TextStyle(
//                           color: AppColors.primaryColor,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w400,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
