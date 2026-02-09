import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class AppStyles {
  // --- Purely Structural Styles (No context-dependent color) ---
  static const TextStyle base = TextStyle(fontFamily: 'Inter');

  // --- Legacy Compatibility (DEPRECATED: Use methods below instead) ---
  static const TextStyle f10w4 = TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400);
  static const TextStyle f14w4 = TextStyle(fontSize: 14, color: AppColors.textPrimaryColor, fontWeight: FontWeight.w400);
  static const TextStyle f14w6 = TextStyle(fontSize: 14, color: AppColors.primaryColor, fontWeight: FontWeight.w600);
  static const TextStyle f14w7 = TextStyle(fontSize: 14, color: AppColors.primaryColor, fontWeight: FontWeight.w700);
  static const TextStyle f16w7 = TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.w700);
  static const TextStyle f12w4 = TextStyle(fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.w400);
  static const TextStyle f12w6 = TextStyle(fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.w600);
  static const TextStyle f12w7 = TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700);
  static const TextStyle f12w5 = TextStyle(fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.w500);
  static const TextStyle f16w6 = TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.w600);
  static const TextStyle f16w5 = TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.w500);
  static const TextStyle f16w4 = TextStyle(fontSize: 16, color: AppColors.textPrimaryColor, fontWeight: FontWeight.w400);
  static const TextStyle f14w5 = TextStyle(fontSize: 14, color: AppColors.notificationColor, fontWeight: FontWeight.w500);
  static const TextStyle f18w4 = TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.textGreyColor);
  static const TextStyle f18w6 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryColor);
  static const TextStyle f20w4 = TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.textPrimaryColor);
  static const TextStyle f20w5 = TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimaryColor);
  static const TextStyle f24w7 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimaryColor);

  // --- Theme-Aware Styles (Recommended) ---
  
  static TextStyle f10w4Th(BuildContext context) => base.copyWith(
    fontSize: 10,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    fontWeight: FontWeight.w400,
  );

  static TextStyle f14w4Th(BuildContext context) => base.copyWith(
    fontSize: 14,
    color: Theme.of(context).colorScheme.onSurface,
    fontWeight: FontWeight.w400,
  );

  static TextStyle f14w6Th(BuildContext context) => base.copyWith(
    fontSize: 14,
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.w600,
  );

  static TextStyle f14w7Th(BuildContext context) => base.copyWith(
    fontSize: 14,
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.w700,
  );

  static TextStyle f16w7Th(BuildContext context) => base.copyWith(
    fontSize: 16,
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.w700,
  );

  static TextStyle f12w4Th(BuildContext context) => base.copyWith(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onSurface,
    fontWeight: FontWeight.w400,
  );

  static TextStyle f12w6Th(BuildContext context) => base.copyWith(
    fontSize: 12,
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.w600,
  );

  static TextStyle f12w7Th(BuildContext context) => base.copyWith(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onPrimary,
    fontWeight: FontWeight.w700,
  );

  static TextStyle f12w5Th(BuildContext context) => base.copyWith(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onSurface,
    fontWeight: FontWeight.w500,
  );

  static TextStyle f16w6Th(BuildContext context) => base.copyWith(
    fontSize: 16,
    color: Theme.of(context).colorScheme.onSurface,
    fontWeight: FontWeight.w600,
  );

  static TextStyle f16w5Th(BuildContext context) => base.copyWith(
    fontSize: 16,
    color: Theme.of(context).colorScheme.onSurface,
    fontWeight: FontWeight.w500,
  );

  static TextStyle f16w4Th(BuildContext context) => base.copyWith(
    fontSize: 16,
    color: Theme.of(context).colorScheme.onSurface,
    fontWeight: FontWeight.w400,
  );

  static TextStyle f14w5Th(BuildContext context) => base.copyWith(
    fontSize: 14,
    color: Theme.of(context).colorScheme.secondary, // success/notification
    fontWeight: FontWeight.w500,
  );

  static TextStyle f18w4Th(BuildContext context) => base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
  );

  static TextStyle f18w6Th(BuildContext context) => base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle f20w4Th(BuildContext context) => base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle f20w5Th(BuildContext context) => base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle f24w7Th(BuildContext context) => base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // --- Pinput Themes (Apple-like Refinement) ---

  static PinTheme defaultPinTheme(BuildContext context) {
    final theme = Theme.of(context);
    return PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  static PinTheme focusedPinTheme(BuildContext context) {
    final theme = Theme.of(context);
    return defaultPinTheme(context).copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  static PinTheme submittedPinTheme(BuildContext context) {
    final theme = Theme.of(context);
    return defaultPinTheme(context).copyWith(
      decoration: defaultPinTheme(context).decoration?.copyWith(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
    );
  }

  static PinTheme errorPinTheme(BuildContext context) {
    final theme = Theme.of(context);
    return defaultPinTheme(context).copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error, width: 1.5),
      ),
    );
  }
}
