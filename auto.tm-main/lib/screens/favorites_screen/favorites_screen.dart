import 'package:auto_tm/global_widgets/refresh_indicator.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/favorites_screen/widgets/subscribed_brands_screen.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_item.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/post_details_screen.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesScreenTab extends StatelessWidget {
  FavoritesScreenTab({super.key});

  final FavoritesController favController = Get.put(FavoritesController());

  @override
  Widget build(BuildContext context) {
    favController.refreshData();
    return Obx(
      () {
        if (favController.favoriteProducts.isEmpty) {
          return SRefreshIndicator(
            onRefresh: favController.refreshData,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Text(
                  'Halan harytlaryňyz ýok'.tr,
                  style: AppStyles.f16w7,
                ),
              ),
            ),
          );
        }
        return SRefreshIndicator(
          onRefresh: favController.refreshData,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: favController.favoriteProducts.length,
                itemBuilder: (context, index) {
                  Post posts = favController.favoriteProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => PostDetailsScreen(),
                          arguments: posts.uuid.toString());
                    },
                    child: PostItem(
                      uuid: posts.uuid,
                      brand: posts.brand,
                      model: posts.model,
                      price: posts.price,
                      photoPath: posts.photoPath,
                      year: posts.year,
                      milleage: posts.milleage,
                      currency: posts.currency,
                      createdAt: posts.createdAt,
                      location: posts.location,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyFavouritesScreen extends StatelessWidget {
  MyFavouritesScreen({super.key});

  final FavoritesController favoritesController =
      Get.put(FavoritesController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "My favourites".tr,
          style: AppStyles.f18w6.copyWith(color: theme.colorScheme.primary),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(
                () => Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.textTertiaryColor, width: 0.4),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => favoritesController.toggleTab(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 16),
                            decoration: BoxDecoration(
                              color: favoritesController.showPosts.value
                                  ? const Color(0xFFC4C4C4)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Post'.tr,
                              style: TextStyle(
                                color: favoritesController.showPosts.value
                                    ? AppColors.textSecondaryColor
                                    : theme.colorScheme
                                        .primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => favoritesController.toggleTab(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 16),
                            decoration: BoxDecoration(
                              color: !favoritesController.showPosts.value
                                  ? const Color(0xFFC4C4C4)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Search follow'.tr,
                              style: TextStyle(
                                color: !favoritesController.showPosts.value
                                    ? AppColors.textSecondaryColor
                                    : theme.colorScheme
                                        .primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () {
                if (favoritesController.showPosts.value) {
                  return FavoritesScreenTab();
                } else {
                  return const SubscribedBrandsListWidget();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
