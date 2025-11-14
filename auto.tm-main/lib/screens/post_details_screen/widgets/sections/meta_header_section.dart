import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Header section displaying brand, model, and posted date
class MetaHeaderSection extends StatelessWidget {
  final Post post;
  final FavoritesController favoritesController;
  final ThemeData theme;

  const MetaHeaderSection({
    super.key,
    required this.post,
    required this.favoritesController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand + Model
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${post.brand} ${post.model}',
              style: AppStyles.f24w7.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Posted date badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(
              vertical: 3,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.dateColor,
            ),
            child: Text(
              '${'Posted date:'.tr} ${favoritesController.formatDate(post.createdAt)}',
              style: AppStyles.f12w4.copyWith(
                color: const Color(0xFF403A3A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
