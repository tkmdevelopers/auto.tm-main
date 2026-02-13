import 'package:auto_tm/screens/auth_screens/login_screen/widgets/main_button.dart';
import 'package:auto_tm/screens/auth_screens/login_screen/widgets/text_field_phone.dart';
import 'package:auto_tm/screens/auth_screens/register_screen/controller/register_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class SRegisterPage extends StatelessWidget {
  SRegisterPage({super.key});

  final RegisterPageController getController =
      Get.find<RegisterPageController>();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => getController.unFocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => getController.goBack(),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: height * 0.05),
                //! logo
                SvgPicture.asset(
                  AppImages.appLogoSvg,
                  height: height * 0.25,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                  // color: theme.colorScheme.primary,
                ),

                //? margin
                SizedBox(height: height * 0),

                //! welcomeback message
                Text(
                  'Create account'.tr,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                //? margin
                SizedBox(height: height * 0.05),

                Row(
                  children: [
                    Text(
                      'Phone number'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.01),

                //! phone textfield
                SLoginTextField(
                  isObscure: false,
                  controller: getController.phoneController,
                  focusNode: getController.phoneFocus,
                ),

                SizedBox(height: height * 0.02),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Obx(
                      () => Checkbox(
                        value: getController.isChecked.value,
                        onChanged: (value) {
                          getController.toggleCheckbox(value);
                        },
                        activeColor: AppColors.primaryColor,
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.bottomSheet(
                          Container(height: height * 0.5),
                          backgroundColor: AppColors.whiteColor,
                          isDismissible: true,
                          isScrollControlled: true,
                        ),
                        child: RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            text: 'Dowam etmek bilen men ',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: 'gizlinlik syýasatyny ',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: 'we ',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: 'ulanmak düzgünlerini ',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: 'kabul edýärin',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.03),

                //! login button
                Obx(
                  () => SButton(
                    title: "Register",
                    buttonColor:
                        (getController.isChecked.value &&
                            getController.phoneController.text.trim().length ==
                                8)
                        ? AppColors.primaryColor
                        : AppColors.textSecondaryColor,
                    onTap:
                        getController.isChecked.value &&
                            getController.phoneController.text.trim().length ==
                                8
                        ? () {
                            getController.registerNewUser();
                          }
                        : () {
                            Get.rawSnackbar(
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: AppColors.whiteColor,
                              borderRadius: 12,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              padding: const EdgeInsets.all(16),
                              duration: const Duration(milliseconds: 1800),
                              animationDuration: const Duration(
                                milliseconds: 250,
                              ),
                              boxShadows: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    (0.2 * 255).round(),
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              messageText: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.secondaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Accept Privacy Policy and enter your valid number to continue'
                                        .tr,
                                    style: TextStyle(
                                      color: AppColors.textPrimaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                  ),
                ),
                SizedBox(height: height * 0.01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
