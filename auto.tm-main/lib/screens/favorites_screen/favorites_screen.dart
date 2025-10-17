import 'package:auto_tm/global_widgets/refresh_indicator.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_item.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/post_details_screen.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesScreenTab extends StatelessWidget {
  FavoritesScreenTab({super.key});

  final FavoritesController favController = Get.put(FavoritesController());

  @override
  Widget build(BuildContext context) {
    // Data refresh is handled in controller onInit to avoid redundant calls here.
    return Obx(() {
      final items = favController.favoriteProducts;
      if (items.isEmpty) {
        return SRefreshIndicator(
          onRefresh: favController.refreshData,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'favourites_empty'.tr,
                style: AppStyles.f16w7,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      return SRefreshIndicator(
        onRefresh: favController.refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final Post post = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
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
                  year: post.year,
                  milleage: post.milleage,
                  currency: post.currency,
                  createdAt: post.createdAt,
                  location: post.location,
                  region: post.region,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class MyFavouritesScreen extends StatelessWidget {
  MyFavouritesScreen({super.key});

  final FavoritesController favoritesController = Get.put(FavoritesController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'My favourites'.tr,
          style: AppStyles.f18w6.copyWith(color: theme.colorScheme.onSurface),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FavoritesScreenTab(),
      ),
    );
  }
}
