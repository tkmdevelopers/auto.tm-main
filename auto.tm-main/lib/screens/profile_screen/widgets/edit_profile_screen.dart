import 'package:auto_tm/screens/auth_screens/login_screen/widgets/text_field_text.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/screens/profile_screen/widgets/location_select.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/screens/profile_screen/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  // Ensure we DO NOT create multiple instances (which caused duplicate fetches & FocusNode disposal).
  // Reuse existing controller if registered; otherwise create a permanent one for app session.
  final ProfileController controller = ProfileController.ensure();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Trigger profile fetch+populate only if not already loaded or currently fetching.
    if (!(controller.hasLoadedProfile.value ||
        controller.isFetchingProfile.value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchProfileAndPopulateFields();
      });
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        title: Text(
          'Edit profile'.tr,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: true,
        actions: [
          TextButton(
            onPressed: controller.uploadProfile,
            child: Text(
              'Done'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (controller.isLoading.value)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Loading profile...'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!controller.hasLoadedProfile.value &&
                    !controller.isLoading.value)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Profile data not loaded yet. You can fill the form now or retry.'
                                .tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.75,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (!controller.isFetchingProfile.value) {
                              controller.fetchProfile();
                            }
                          },
                          child: Text(
                            'Retry'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (controller.isRefreshing.value)
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.6,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Refreshing...'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Avatar block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Obx(
                      () => ProfileAvatar(
                        radius: 40,
                        backgroundRadiusDelta: 4,
                        localBytes: controller.selectedImage.value,
                        remotePath: controller.profile.value?.avatar,
                        onTap: controller.pickImage,
                      ),
                    ),
                    TextButton(
                      onPressed: controller.pickImage,
                      child: Text(
                        'Change avatar'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ProfileFormFields(
                  label: 'Name'.tr,
                  controller: controller.nameController,
                  focus: controller.nameFocus,
                  onsubmit: (_) => controller.nameFocus.unfocus(),
                  hint: 'Enter your name'.tr,
                ),
                GestureDetector(
                  onTap: () async {
                    final selected = await Get.to(
                      () => SLocationSelectionProfile(),
                    );
                    if (selected != null && selected is String) {
                      controller.location.value = selected;
                      controller.locationController.text = selected;
                      final box = GetStorage();
                      box.write('user_location', selected);
                    }
                  },
                  child: AbsorbPointer(
                    child: ProfileFormFields(
                      label: 'Location'.tr,
                      controller: controller.locationController,
                      focus: controller.locationFocus,
                      hint: 'Enter your location'.tr,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class ProfileFormFields extends StatelessWidget {
  const ProfileFormFields({
    super.key,
    required this.label,
    required this.controller,
    required this.focus,
    this.onsubmit,
    required this.hint,
    this.type,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focus;
  final void Function(String)? onsubmit;
  final TextInputType? type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 6),
        STextField(
          isObscure: false,
          controller: controller,
          focusNode: focus,
          onSubmitted: onsubmit,
          hintText: hint,
          type: type,
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
