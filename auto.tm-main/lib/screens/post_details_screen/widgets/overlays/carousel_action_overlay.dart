import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overlay with back button and favorite toggle on carousel
class CarouselActionOverlay extends StatelessWidget {
  final ThemeData theme;
  final PostDetailsController detailsController;
  final FavoritesController favoritesController;

  const CarouselActionOverlay({
    super.key,
    required this.theme,
    required this.detailsController,
    required this.favoritesController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () => Get.back(),
            ),
          ),
          // Favorite toggle
          Obx(() {
            final postValue = detailsController.post;
            final uuidVal = postValue?.uuid;
            final isFav =
                uuidVal != null && favoritesController.favorites.contains(uuidVal);
            return CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color: isFav ? theme.colorScheme.primary : Colors.white,
                ),
                onPressed: () {
                  if (uuidVal != null) {
                    favoritesController.toggleFavorite(uuidVal);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
