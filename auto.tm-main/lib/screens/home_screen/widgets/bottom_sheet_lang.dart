import 'package:auto_tm/constants/constants.dart';
import 'package:auto_tm/global_controllers/language_controller.dart';
import 'package:auto_tm/global_controllers/theme_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

// --- REFACRORED & RESPONSIVE WIDGET ---
// This version is now wrapped in a SingleChildScrollView to prevent pixel
// overflows on smaller screens or with larger font sizes.

class BottomSheetLang extends StatelessWidget {
  BottomSheetLang({super.key, required this.width});

  final double width;
  final LanguageController langController = Get.put(LanguageController());
  final ThemeController themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      // SafeArea ensures UI is not obscured by system elements like the home bar
      child: SafeArea(
        top: false, // Not needed at the top of a bottom sheet
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section for Language Selection
                _buildHeader(context, "Language".tr),
                _buildLanguageList(context),
                const SizedBox(height: 8),
                const Divider(),

                // Section for Settings (e.g., Theme)
                _buildSettingsList(context),
                const Divider(),
                const SizedBox(height: 8),

                // Section for About Us
                _buildHeader(context, 'About us'.tr),
                _buildAboutList(context),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a styled header for a section.
  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Builds the list of selectable languages.
  Widget _buildLanguageList(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Column(
        children: HomeConsts.languages.map((language) {
          final bool isSelected =
              langController.selectedLanguage.value == language['name'];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            title: Text(
              language['name'],
              style: AppStyles.f14w4.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            onTap: () {
              NavigationUtils.close(context); // Close the bottom sheet
              langController.updateLanguage(
                language['name'],
                language['language_code'],
                language['country_code'],
              );
            },
          );
        }).toList(),
      ),
    );
  }

  /// Builds the settings items, like the dark mode toggle.
  Widget _buildSettingsList(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(
          Icons.brightness_6_outlined,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
        title: Text(
          'Dark mode'.tr,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: themeController.isDark.value,
            onChanged: (value) {
              themeController.toggleTheme(value);
            },
            activeColor: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  /// Builds the 'About Us' information section.
  Widget _buildAboutList(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        ListTile(
          leading: SvgPicture.asset(
            AppImages.phone,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            height: 20,
            width: 20,
          ),
          title: const Text('+993 62342637'),
          dense: true,
        ),
        ListTile(
          leading: SvgPicture.asset(
            AppImages.instagram,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            height: 20,
            width: 20,
          ),
          title: const Text('@alphamotors'),
          dense: true,
        ),
      ],
    );
  }
}
