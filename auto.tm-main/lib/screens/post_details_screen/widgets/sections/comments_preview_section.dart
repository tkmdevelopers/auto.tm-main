import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/comments_carousel.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/comments.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:auto_tm/ui_components/colors.dart';

class CommentsPreviewSection extends StatelessWidget {
  final String? postUuid; // nullable for safety
  final ThemeData theme;
  const CommentsPreviewSection({
    super.key,
    required this.postUuid,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (postUuid == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments'.tr,
            style: AppStyles.f20w5.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.textTertiaryColor, height: 0.5),
          const SizedBox(height: 16),
          Row(
            children: [Expanded(child: CommentCarousel(postId: postUuid!))],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final uuid = postUuid;
              if (uuid != null) {
                Get.to(() => const CommentsPage(), arguments: uuid);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textTertiaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 30),
            ),
            child: Text(
              'Show all'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
