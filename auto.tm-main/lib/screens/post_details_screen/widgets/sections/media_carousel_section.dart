import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/components/carousel_image_item.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/components/page_indicator_dots.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/overlays/carousel_action_overlay.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/overlays/video_cta_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Media carousel section showing photo gallery with navigation overlays
class MediaCarouselSection extends StatelessWidget {
  final Post post;
  final String uuid;
  final PostDetailsController detailsController;
  final FavoritesController favoritesController;

  const MediaCarouselSection({
    super.key,
    required this.post,
    required this.uuid,
    required this.detailsController,
    required this.favoritesController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
              clipBehavior: Clip.none,
              children: [
                // Main carousel
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                  ),
                  child: CarouselSlider.builder(
                    itemCount: post.photos.length,
                    itemBuilder: (context, index, realIndex) {
                      final photos = post.photos;
                      if (index >= photos.length) {
                        return const SizedBox();
                      }
                      final photo = photos[index];

                      return CarouselImageItem(
                        key: PageStorageKey('carousel_img_$index'),
                        photo: photo,
                        photos: photos,
                        index: index,
                        uuid: uuid,
                        theme: theme,
                      );
                    },
                    options: CarouselOptions(
                      // Fix #8: Dynamic carousel height based on screen
                      height: MediaQuery.of(context).size.height * 0.4,
                      enlargeCenterPage: false,
                      enableInfiniteScroll: false,
                      autoPlay: false,
                      viewportFraction: 1,
                      disableCenter: true,
                      onPageChanged: (index, reason) {
                        detailsController.setCurrentPage(index);
                      },
                    ),
                  ),
                ),

                // Action overlay (back + favorite buttons)
                CarouselActionOverlay(
                  theme: theme,
                  detailsController: detailsController,
                  favoritesController: favoritesController,
                ),

                // Page indicator dots
                PageIndicatorDots(
                  detailsController: detailsController,
                ),

                // Video CTA button
                VideoCtaButton(
                  detailsController: detailsController,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
