import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

/// The phone-number + OTP verification section of the post form.
///
/// Displays a phone input with an optional "Verified" chip and, when OTP is
/// required, the OTP pin-input field plus send/verify buttons.
class PostContactSection extends StatelessWidget {
  const PostContactSection({
    super.key,
    required this.postController,
    required this.onFieldChanged,
  });

  final PostController postController;

  /// Forwarded to the phone [PostTextFormField] so the parent can mark the
  /// form as dirty.
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      return Column(
        children: [
          PostTextFormField(
            label: 'Phone number'.tr,
            controller: postController.phoneController,
            keyboardType: TextInputType.phone,
            hint: '61234567',
            prefixText: '+993 ',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            isRequired: true,
            onFieldChanged: onFieldChanged,
            suffix: Obx(() {
              final showChip =
                  postController.isPhoneVerified.value &&
                  !postController.needsOtp.value;
              if (!showChip) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'post_verified'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (!postController.isPhoneVerified.value &&
              postController.needsOtp.value)
            _buildOtpBlock(context, theme),
        ],
      );
    });
  }

  Widget _buildOtpBlock(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        if (postController.showOtpField.value)
          Pinput(
            length: 5,
            defaultPinTheme: PinTheme(
              width: 48,
              height: 56,
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 48,
              height: 56,
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.onSurface),
              ),
            ),
            focusNode: postController.otpFocus,
            controller: postController.otpController,
            onCompleted: (pin) => postController.verifyOtp(),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: postController.showOtpField.value
                ? const Icon(Icons.check_circle_outline)
                : const Icon(Icons.send_outlined),
            label: Text(
              postController.showOtpField.value
                  ? 'post_verify_otp'.tr
                  : 'post_send_otp'.tr,
            ),
            onPressed: postController.showOtpField.value
                ? () => postController.verifyOtp()
                : (postController.isSendingOtp.value
                      ? null
                      : () => postController.sendOtp()),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Obx(() {
          if (postController.countdown.value > 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'post_resend_code_in'.trParams({
                  'seconds': postController.countdown.value.toString(),
                }),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          } else if (postController.showOtpField.value) {
            return TextButton(
              onPressed: () => postController.sendOtp(),
              child: Text('post_resend_code'.tr),
            );
          } else {
            return const SizedBox.shrink();
          }
        }),
      ],
    );
  }
}
