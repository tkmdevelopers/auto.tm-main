import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Video call-to-action button overlay on carousel
class VideoCtaButton extends StatelessWidget {
  final PostDetailsController detailsController;

  const VideoCtaButton({
    super.key,
    required this.detailsController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Fix #3: Consistent null safety
      final post = detailsController.post;
      final video = post?.video;
      final bool hasVideo = video != null && video.isNotEmpty;

      return Positioned(
        // Fix #11: Position button inside carousel bounds
        bottom: 12.0, // Changed from -12.0 to 12.0
        right: 16.0,
        child: hasVideo
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Safe to use ! here since hasVideo checks it
                  Get.to(
                    () => VideoPlayerPage(),
                    arguments: video,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF1E4EED),
                        Color(0xFF7FA7F6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(
                    minHeight: 36,
                    minWidth: 140,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: AppColors.whiteColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'post_watch_video'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      );
    });
  }
}
