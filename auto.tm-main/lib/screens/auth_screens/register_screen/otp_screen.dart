import 'package:auto_tm/screens/auth_screens/login_screen/widgets/main_button.dart';
import 'package:auto_tm/screens/auth_screens/register_screen/controller/register_controller.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatelessWidget {
  final bool returnOnSuccess; // if true, Navigator.pop with success
  OtpScreen({super.key, this.returnOnSuccess = false});

  // Use ensure pattern to prevent "Controller not found" errors
  final RegisterPageController getController = RegisterPageController.ensure();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => getController.unFocus(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        _Logo(theme: theme, height: height * 0.25),
                        const SizedBox(height: 24),
                        Text(
                          'Verification'.tr,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Subtitle(theme: theme, controller: getController),
                        const SizedBox(height: 32),
                        _OtpInput(theme: theme, controller: getController),
                        const SizedBox(height: 32),
                        Obx(() {
                          final enabled =
                              getController.otpValue.value.length == 5 &&
                              !getController.isLoading.value;
                          return Column(
                            children: [
                              SButton(
                                title: getController.isLoading.value
                                    ? '...'
                                    : 'Submit',
                                buttonColor: enabled
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.25,
                                      ),
                                onTap: enabled
                                    ? () async {
                                        final before = Get.currentRoute;
                                        await getController.checkOtp();
                                        if (returnOnSuccess &&
                                            Get.currentRoute == before) {
                                          NavigationUtils.close(
                                            context,
                                            result: true,
                                          );
                                        }
                                      }
                                    : () {},
                              ),
                              const SizedBox(height: 20),
                              _ResendRow(
                                theme: theme,
                                controller: getController,
                              ),
                            ],
                          );
                        }),
                        const Spacer(),
                        _Footer(theme: theme),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- Subcomponents for clearer structure ---
class _Logo extends StatelessWidget {
  const _Logo({required this.theme, required this.height});
  final ThemeData theme;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: SvgPicture.asset(
        AppImages.appLogoSvg,
        height: height,
        colorFilter: ColorFilter.mode(
          theme.colorScheme.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.theme, required this.controller});
  final ThemeData theme;
  final RegisterPageController controller;
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'Enter the OTP code sent to '.tr,
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.75),
          fontWeight: FontWeight.w400,
        ),
        children: [
          TextSpan(
            text: ' +993 ${controller.phoneController.text}',
            style: AppStyles.f16w4.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  const _OtpInput({required this.theme, required this.controller});
  final ThemeData theme;
  final RegisterPageController controller;
  @override
  Widget build(BuildContext context) {
    final base = AppStyles.defaultPinTheme;
    final focused = AppStyles.focusedPinTheme.copyWith(
      decoration: AppStyles.focusedPinTheme.decoration?.copyWith(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
    );
    return Center(
      child: Pinput(
        length: 5,
        defaultPinTheme: base.copyWith(
          decoration: base.decoration?.copyWith(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        focusedPinTheme: focused,
        focusNode: controller.otpFocus,
        controller: controller.otpController,
        onChanged: (val) => controller.otpValue.value = val,
        onCompleted: (val) => controller.otpValue.value = val,
        cursor: Container(width: 2, color: theme.colorScheme.primary),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.theme, required this.controller});
  final ThemeData theme;
  final RegisterPageController controller;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ".tr,
          style: AppStyles.f14w4.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.75),
          ),
        ),
        TextButton(
          onPressed: () => controller.requestOtp(),
          child: Text(
            'Resend'.tr,
            style: AppStyles.f14w4.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.theme});
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 12),
      child: Text(
        'Secure verification'.tr,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
