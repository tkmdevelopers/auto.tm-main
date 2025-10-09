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
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: favController.favoriteProducts.length + 1, // +1 for top spacer
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const SizedBox(height: 12); // top space below AppBar
                  }
                  final realIndex = index - 1;
                  Post posts = favController.favoriteProducts[realIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
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
                        region: posts.region,
                      ),
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

  final FavoritesController favoritesController = Get.put(FavoritesController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ensure favorites are loaded
    favoritesController.refreshData();

    return Scaffold(
      appBar: AppBar(
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
