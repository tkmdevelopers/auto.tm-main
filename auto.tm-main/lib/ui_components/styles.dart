import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class AppStyles {
  static const TextStyle f10w4 = TextStyle(
    fontSize: 10,
    color: Color(0xFF94A3B8),
    fontWeight: FontWeight.w400,
  );

  static const TextStyle f14w4 = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimaryColor,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle f14w6 = TextStyle(
    fontSize: 14,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w600,
  );

  // static TextStyle f12w6 = TextStyle(
  //   fontSize: Functionalities.fontSize(14),
  //   color: AppColors.primaryColor,
  //   fontWeight: FontWeight.w600,
  // );

  static const TextStyle f14w7 = TextStyle(
    fontSize: 14,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle f16w7 = TextStyle(
    fontSize: 16,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle f12w4 = TextStyle(
    fontSize: 12,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle f12w6 = TextStyle(
    fontSize: 12,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle f12w7 = TextStyle(
    fontSize: 12,
    color: Colors.white,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle f12w5 = TextStyle(
    fontSize: 12,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle f16w6 = TextStyle(
    fontSize: 16,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle f16w5 = TextStyle(
    fontSize: 16,
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle f16w4 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimaryColor,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle f14w5 = TextStyle(
    fontSize: 14,
    color: AppColors.notificationColor,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle f18w4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textGreyColor,
  );

  static const TextStyle f18w6 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  static const TextStyle f20w4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryColor,
  );

  static const TextStyle f20w5 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryColor,
  );

  static const TextStyle f24w7 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryColor,
  );

  static PinTheme defaultPinTheme = PinTheme(
    width: 50,
    height: 50,
    textStyle: const TextStyle(fontSize: 16, color: AppColors.textPrimaryColor),
    decoration: BoxDecoration(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.textFieldBorderColor),
    ),
  );

  static PinTheme focusedPinTheme = defaultPinTheme.copyWith(
    decoration: BoxDecoration(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.primaryColor),
    ),
  );
}
