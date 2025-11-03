import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/home_screen/controller/category_controller.dart';
import 'package:auto_tm/screens/home_screen/model/category_model.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_item.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryPosts extends StatelessWidget {
  final CategoryController controller = Get.put(CategoryController());
  final FavoritesController favoritesController = Get.put(
    FavoritesController(),
  );
  final uuid = Get.arguments;

  CategoryPosts({super.key});

  @override
  Widget build(BuildContext context) {
    // controller.fetchCategoryPosts(uuid);
    // final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: AppColors.whiteColor,
        // surfaceTintColor: theme.appBarTheme.backgroundColor,
        automaticallyImplyLeading: true,
        title: Text('something'.tr),
      ),
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Obx(() {
          // Show loading indicator while fetching
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: AppColors.primaryColor,
                valueColor: AlwaysStoppedAnimation(AppColors.scaffoldColor),
              ),
            );
          } else if (controller.category.isEmpty) {
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Internetiňizi barlaň'.tr, style: AppStyles.f16w7),
                  TextButton(
                    onPressed: () {
                      controller.fetchCategoryPosts(uuid);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: AppColors.primaryColor,
                        ),
                        Text('Täzele'.tr, style: AppStyles.f12w4),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            Category category = controller.category[0];
            return GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              physics: BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 posts per row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.65, // Adjust for design
              ),
              itemCount: category.posts.length,
              itemBuilder: (context, index) {
                Post posts = category.posts[index];
                return PostItem(
                  uuid: posts.uuid,
                  brand: posts.brand,
                  model: posts.model,
                  price: posts.price,
                  photoPath: posts.photoPath,
                  photos: posts.photos, // Phase 2.1: Pass aspect ratio metadata
                  year: posts.year,
                  milleage: posts.milleage,
                  currency: posts.currency,
                  createdAt: posts.createdAt,
                  location: posts.location,
                  region: posts.region,
                );
              },
            );
          }
        }),
      ),
    );
  }
}
