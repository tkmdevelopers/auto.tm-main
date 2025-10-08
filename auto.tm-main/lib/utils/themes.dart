// theme.dart
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:auto_tm/utils/color_extensions.dart';

class AppThemes {
  static final light = ThemeData(
    fontFamily: 'Inter',
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.scaffoldColor,
    primaryColor: AppColors.primaryColor, // Black for light mode
    shadowColor: Colors.transparent,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardColor,
      surfaceTintColor: AppColors.cardColor,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryColor),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.cardColor,
      surfaceTintColor: AppColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardColor,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.textTertiaryColor,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    // Icon Theme
    primaryIconTheme: IconThemeData(color: AppColors.textPrimaryColor),
    iconTheme: IconThemeData(color: AppColors.textSecondaryColor),

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryColorLightMode, // Primary brand color
      primaryContainer: AppColors.primaryColorLightMode.alphaPct(0.10),
      secondary: AppColors.brandColor, // Accent color
      secondaryContainer: AppColors.brandColor.alphaPct(0.10),
      surface: AppColors.cardColor,
      // background deprecated -> rely on scaffoldBackground + surface usages
      tertiary: AppColors.surfaceColor,
      tertiaryContainer: AppColors.searchFieldColor,
      onPrimary: AppColors.textOnPrimaryColor,
      onSecondary: AppColors.textOnPrimaryColor,
      onSurface: AppColors.textPrimaryColor,
      // onBackground removed (deprecated) -> consolidate to onSurface
      outline: AppColors.textFieldBorderColor,
      outlineVariant: AppColors.iconBorderColor,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.searchFieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textFieldBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textFieldBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryColorDarkMode,
          width: 2,
        ), // Red focus border
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorColor),
      ),
    ),
  );

  static final dark = ThemeData(
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldColorDark,
    primaryColor: AppColors.primaryColorDarkMode, // Red for dark mode
    shadowColor: Colors.transparent,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardColorDark,
      surfaceTintColor: AppColors.cardColorDark,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryColorDark),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryColorDark, // Light text for dark mode
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.cardColorDark,
      surfaceTintColor: AppColors.cardColorDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardColorDark,
      selectedItemColor: AppColors.brandColor,
      unselectedItemColor: AppColors.textTertiaryColorDark,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    // Icon Theme
    primaryIconTheme: IconThemeData(color: AppColors.textPrimaryColorDark),
    iconTheme: IconThemeData(color: AppColors.textSecondaryColorDark),

    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColorDarkMode, // Primary brand color
      primaryContainer: AppColors.primaryColorDarkMode.alphaPct(0.20),
      secondary: AppColors.secondaryColor,
      secondaryContainer: AppColors.surfaceColorDark,
      surface: AppColors.cardColorDark,
      // background deprecated -> rely on scaffoldBackground + surface
      tertiary: AppColors.surfaceColorDark,
      tertiaryContainer: AppColors.searchFieldColorDark,
      onPrimary: AppColors.textOnPrimaryColor,
      onSecondary: AppColors.textOnPrimaryColor,
      onSurface: AppColors.textPrimaryColorDark,
      // onBackground removed (deprecated) -> consolidated to onSurface
      outline: AppColors.textFieldBorderColorDark,
      outlineVariant: AppColors.iconBorderColorDark,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.cardColorDark,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.searchFieldColorDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textFieldBorderColorDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textFieldBorderColorDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryColorDarkMode,
          width: 2,
        ), // Red focus border
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorColor),
      ),
    ),
  );
}
