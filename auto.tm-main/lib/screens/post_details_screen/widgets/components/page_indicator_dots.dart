import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Page indicator dots showing current photo position in carousel
class PageIndicatorDots extends StatelessWidget {
  final PostDetailsController detailsController;

  const PageIndicatorDots({
    super.key,
    required this.detailsController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(105, 0, 0, 0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(() {
              final photos = detailsController.post?.photoPaths;

              if (photos == null || photos.isEmpty) {
                return const SizedBox(); // or placeholder
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (index) {
                  return Obx(
                    () => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: detailsController.currentPage.value == index
                            ? AppColors.primaryColor
                            : AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}
