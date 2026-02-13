import 'package:auto_tm/screens/auth_screens/login_screen/widgets/text_field_phone.dart';
import 'package:auto_tm/screens/auth_screens/login_screen/widgets/text_field_text.dart';
import 'package:auto_tm/screens/home_screen/controller/premium_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:auto_tm/utils/functionalities.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class PremiumPage extends StatelessWidget {
  PremiumPage({super.key});
  final controller = Get.put(PremiumController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        title: Text(
          'Premium'.tr,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(
        () => Column(
          children: [
            Expanded(
              child: ListView(
                // itemCount: controller.subscriptions.length,
                children: [
                  ...controller.subscriptions.map((item) {
                    // final item = controller.subscriptions[index];

                    return Obx(() {
                      final isSelected =
                          item.uuid == controller.selectedId.value;
                      return GestureDetector(
                        onTap: () => controller.selectedId.value = item.uuid,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor,
                                blurRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? HexColor.fromHex(item.color)
                                  : AppColors.textSecondaryColor,
                              width: isSelected ? 2 : 0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            // color: HexColor.fromHex(item.color),
                            color: theme.colorScheme.primaryContainer,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.network(
                                        '${ApiKey.ip}${item.iconPath}',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: SvgPicture.asset(
                                                AppImages.defaultImageSvg,
                                                height: 24,
                                                width: 24,
                                                colorFilter: ColorFilter.mode(
                                                  theme.colorScheme.primary,
                                                  BlendMode.srcIn,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        item.getLocalizedTitle(Get.locale?.languageCode ?? 'en'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 1
                                            ..color = HexColor.fromHex(
                                              item.color,
                                            ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${item.price}\$ ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: HexColor.fromHex(item.color),
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'monthly'.tr,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textTertiaryColor,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                item.getLocalizedDescription(Get.locale?.languageCode ?? 'en'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  }),
                  SizedBox(height: 8),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: theme.shadowColor, blurRadius: 5),
                      ],
                      border: Border.all(
                        color: AppColors.textSecondaryColor,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      // color: HexColor.fromHex(item.color),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        STextField(
                          isObscure: false,
                          hintText: 'Write location',
                          controller: controller.location,
                          focusNode: controller.locationFocus,
                          onSubmitted: (value) {
                            controller.locationFocus.unfocus();
                            controller.phoneFocus.requestFocus();
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Phone number'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        SLoginTextField(
                          isObscure: false,
                          hintText: '********',
                          controller: controller.phone,
                          focusNode: controller.phoneFocus,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 16, right: 16),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => ElevatedButton(
                  onPressed:
                      controller.selectedId.value != '' &&
                          controller.location.text.isNotEmpty &&
                          controller.phone.text.isNotEmpty
                      ? controller.submitSubscription
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor:
                        controller.selectedId.value != '' &&
                            controller.location.text.isNotEmpty &&
                            controller.phone.text.isNotEmpty
                        ? AppColors.primaryColor
                        : AppColors.textGreyColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Send".tr,
                    style: AppStyles.f16w5.copyWith(
                      color: AppColors.scaffoldColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
