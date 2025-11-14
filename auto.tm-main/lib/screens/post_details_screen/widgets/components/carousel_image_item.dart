import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/view_post_photo.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Carousel image item with AutomaticKeepAliveClientMixin
/// to prevent disposal and re-initialization when scrolling
class CarouselImageItem extends StatefulWidget {
  final Photo photo;
  final List<Photo> photos;
  final int index;
  final String uuid;
  final ThemeData theme;

  const CarouselImageItem({
    super.key,
    required this.photo,
    required this.photos,
    required this.index,
    required this.uuid,
    required this.theme,
  });

  @override
  State<CarouselImageItem> createState() => _CarouselImageItemState();
}

class _CarouselImageItemState extends State<CarouselImageItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep widget alive when off-screen!

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Get screen dimensions for adaptive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    const carouselHeight = 300.0;

    // AutomaticKeepAliveClientMixin handles keep-alive automatically
    // No need to wrap in AutomaticKeepAlive widget (causes ParentDataWidget error)
    return GestureDetector(
      onTap: () {
        if (widget.photos.isNotEmpty) {
          Get.to(
            () => ViewPostPhotoScreen(
              photos: widget.photos,
              currentIndex: widget.index,
              postUuid: widget.uuid,
              heroGroupTag: widget.uuid,
            ),
            transition: Transition.fadeIn,
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 220),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: carouselHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: widget.theme.colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: widget.photo.bestPath.isNotEmpty
              ? CachedImageHelper.buildAdaptivePostImage(
                  photo: widget.photo,
                  baseUrl: ApiKey.ip,
                  containerWidth: screenWidth,
                  containerHeight: carouselHeight,
                  fit: BoxFit.contain,
                  isThumbnail:
                      false, // High quality for carousel (6x multiplier)
                )
              : Image.asset(
                  AppImages.defaultImagePng,
                  height: carouselHeight,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
