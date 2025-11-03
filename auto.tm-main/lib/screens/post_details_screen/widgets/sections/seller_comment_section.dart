import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:auto_tm/ui_components/colors.dart';

class SellerCommentSection extends StatelessWidget {
  final Post? post;
  final ThemeData theme;
  const SellerCommentSection({
    super.key,
    required this.post,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (post == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller\'s comment'.tr,
            style: AppStyles.f20w5.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.textTertiaryColor, height: 0.5),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  post!.description.isNotEmpty
                      ? post!
                            .description // Do NOT translate user text
                      : '-',
                  style: AppStyles.f16w4.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
