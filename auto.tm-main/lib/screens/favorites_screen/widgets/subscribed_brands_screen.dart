import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_item.dart';
import 'package:auto_tm/screens/post_details_screen/post_details_screen.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Clean implementation replacing previously corrupted / duplicated code.
class SubscribedBrandsListWidget extends StatelessWidget {
  const SubscribedBrandsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavoritesController>();
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoadingSubscribedBrands.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.subscribedBrands.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'favourites_no_subscribed_brands'.tr,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    color: AppColors.textTertiaryColor,
                    height: 0.3,
                  ),
                ),
                itemCount: controller.subscribedBrands.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final brand = controller.subscribedBrands[index];
                  final String brandName =
                      brand['name'] ?? 'favourites_unknown_brand'.tr;
                  final String brandUuid = brand['uuid'] ?? '';
                  final String logoUrl =
                      brand['photo']?['originalPath'] ??
                      brand['photo']?['path'] ??
                      '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    color: theme.scaffoldBackgroundColor,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          if (logoUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Image.network(
                                ApiKey.ip + logoUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: theme.colorScheme.error,
                                    ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              brandName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          // Always "subscribed" for now; switch kept for future toggle.
                          Transform.scale(
                            scale: 0.7,
                            child: CupertinoSwitch(
                              value: true,
                              activeTrackColor: AppColors.primaryColor,
                              onChanged: (bool newValue) {
                                if (brandUuid.isNotEmpty) {
                                  controller.handleBrandSubscriptionToggle(
                                    brandUuid,
                                    newValue,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.subscribeBrandPosts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'favourites_no_subscribed_posts'.tr,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.subscribeBrandPosts.length,
                itemBuilder: (context, index) {
                  final post = controller.subscribeBrandPosts[index];
                  return GestureDetector(
                    onTap: () => Get.to(
                      () => PostDetailsScreen(),
                      arguments: post.uuid.toString(),
                    ),
                    child: PostItem(
                      uuid: post.uuid,
                      brand: post.brand,
                      model: post.model,
                      price: post.price,
                      photoPath: post.photoPath,
                      photos:
                          post.photos, // Phase 2.1: Pass aspect ratio metadata
                      year: post.year,
                      milleage: post.milleage,
                      currency: post.currency,
                      createdAt: post.createdAt,
                      location: post.location,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    });
  }
}
