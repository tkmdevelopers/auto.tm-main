import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/screens/profile_screen/widgets/edit_profile_screen.dart';
import 'package:auto_tm/screens/profile_screen/widgets/profile_avatar.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = ProfileController.ensure();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasLoadedProfile.value &&
          !controller.isFetchingProfile.value) {
        controller.fetchProfile();
      }
    });
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        final user = controller.profile.value;
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.hasLoadedProfile.value &&
            !controller.isFetchingProfile.value) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Profile not loaded yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh or tap retry to fetch your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!controller.isFetchingProfile.value)
                          controller.fetchProfile();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Get.to(() => EditProfileScreen()),
                      child: const Text('Fill Manually'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.maxFinite,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      height: 200,
                      child: SvgPicture.asset(
                        AppImages.appLogoSvg,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Container(
                      width: double.maxFinite,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        color: AppColors.textPrimaryColor.withAlpha(
                          (0.3 * 255).round(),
                        ),
                      ),
                      height: 200,
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          backgroundColor: theme.colorScheme.surface.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Get.to(() => EditProfileScreen()),
                        child: Text(
                          'Edit'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      bottom: -50,
                      child: ProfileAvatar(
                        radius: 46,
                        backgroundRadiusDelta: 4,
                        localBytes: controller.selectedImage.value,
                        remotePath: user?.avatar,
                        onTap: () => Get.to(() => EditProfileScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  user?.name ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF727272),
                  ),
                ),
                // Location now shown inside the details container below; external row removed to prevent duplication
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      width: 0.6,
                      color: theme.colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Username'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                          Text(
                            user?.name ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: theme.colorScheme.outline.withOpacity(0.15), height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Phone number'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                          Text(
                            user?.phone ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (user?.location != null && (user!.location ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(color: theme.colorScheme.outline.withOpacity(0.15), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Location'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withOpacity(0.55),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                user.location!,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      width: 0.6,
                      color: theme.colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Support'.tr,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'alphamotors@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Terms of service'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Privacy Policy'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => controller.logout(),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          backgroundColor: theme.colorScheme.surface.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Log out'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
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
