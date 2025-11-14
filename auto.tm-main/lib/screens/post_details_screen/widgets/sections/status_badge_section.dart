import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Badge showing post status (pending review or declined)
class StatusBadgeSection extends StatelessWidget {
  final Post post;
  final ThemeData theme;

  const StatusBadgeSection({
    super.key,
    required this.post,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if status is not true (pending or declined)
    if (post.status == true) {
      return const SizedBox.shrink();
    }

    final isPending = post.status == null;
    final badgeColor = isPending ? Colors.orange : theme.colorScheme.error;
    final icon = isPending ? Icons.hourglass_top_rounded : Icons.cancel_outlined;
    final text = isPending
        ? 'post_status_pending_review'.tr
        : 'post_status_declined_admin'.tr;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(
          color: badgeColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPending ? Colors.orange.shade700 : badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPending ? Colors.orange.shade700 : badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
