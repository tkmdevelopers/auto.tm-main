// Removed legacy favorites & feature imports (not present in current project structure)
import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/screens/post_details_screen/post_details_screen.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

/// Shimmer widget that matches the PostedPostItem design
class PostedPostItemShimmer extends StatelessWidget {
  const PostedPostItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(12), // Match the actual post item padding
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          16,
        ), // Match the actual post item radius
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: 180, // Match the actual post item fixed height
              child: Container(color: shimmerColor),
            ),
          ),
          const SizedBox(height: 12),
          // Title placeholder
          Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          // Price placeholder
          Container(
            height: 24,
            width: 120,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          // Detail chips placeholder
          Row(
            children: [
              Container(
                height: 24,
                width: 70,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: 90,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Date placeholder
          Container(
            height: 12,
            width: 150,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a posted car item with a clean, modern, and responsive design,
/// inspired by Apple's design guidelines. It emphasizes clarity, depth, and a strong
/// visual hierarchy. Uses adaptive thumbnail sizing for optimal display.
class PostedPostItem extends StatelessWidget {
  final String uuid;
  final String model;
  final String brand;
  final String? brandId;
  final String? modelId;
  final double price;
  final String photoPath;
  final double year;
  final double milleage;
  final String currency;
  final String createdAt;
  final bool? status;
  final int? commentCount; // Number of comments on this post

  PostedPostItem({
    super.key,
    required this.uuid,
    required this.model,
    required this.brand,
    this.brandId,
    this.modelId,
    required this.price,
    required this.photoPath,
    required this.year,
    required this.milleage,
    required this.currency,
    required this.createdAt,
    this.status,
    this.commentCount,
  });

  // Use existing instance if available; do not create a new controller per item
  final PostController postController = Get.isRegistered<PostController>()
      ? Get.find<PostController>()
      : Get.put(PostController());

  Widget _buildNetworkOrPlaceholder(ThemeData theme, BuildContext context) {
    // Get screen width for adaptive sizing
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate optimal thumbnail dimensions
    // Assuming typical grid with padding: screenWidth - 32px (16px each side)
    final containerWidth = screenWidth - 32;
    const containerHeight = 180.0;

    // Use buildPostImage with adaptive container dimensions
    // BoxFit.cover will crop to fill the container regardless of source aspect ratio
    // The image helper will cache at appropriate dimensions (4x multiplier for thumbnails)
    return CachedImageHelper.buildPostImage(
      photoPath: photoPath,
      baseUrl: ApiKey.ip,
      width: containerWidth, // Actual container width
      height: containerHeight, // Fixed height matches container
      fit: BoxFit.cover, // Covers the container, crops if needed
      fallbackUrl:
          'https://placehold.co/${containerWidth.toInt()}x${containerHeight.toInt()}/e0e0e0/666666?text=No+Image',
      isThumbnail:
          true, // Use 4x multiplier for thumbnails (adaptive cached dimensions)
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool? s = status; // reuse for price color decision
    final Color acceptedGreen = Colors.green.shade600;

    return GestureDetector(
      onTap: () {
        // Navigate only if explicitly active (status == true). If null (pending) or false (declined) show info.
        if (status == true) {
          _navigateToPostDetails(uuid);
        } else {
          // Show appropriate message based on status
          final String title;
          final String message;
          final IconData icon;
          final Color bgColor;

          if (status == null) {
            // Pending
            title = 'post_pending_title'.tr;
            message = 'post_pending_message'.tr;
            icon = Icons.hourglass_top_rounded;
            bgColor = Colors.orange;
          } else {
            // Declined
            title = 'post_declined_title'.tr;
            message = 'post_declined_message'.tr;
            icon = Icons.cancel_outlined;
            bgColor = Colors.red;
          }

          Get.closeAllSnackbars();
          Get.snackbar(
            title,
            message,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12),
            backgroundColor: bgColor.withValues(alpha: 0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            icon: Icon(icon, color: Colors.white),
          );
        }
      },
      // APPLE-FRIENDLY REFINEMENT: The main card container.
      // Uses surfaceContainer for a layered look, a subtle border, and softer shadows
      // to create a sense of depth without being distracting.
      child: Container(
        padding: const EdgeInsets.all(
          12,
        ), // Reduced from 16 for more compact look
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Slightly smaller radius
          color: theme.colorScheme.surfaceContainer,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: isDarkMode ? 0.15 : 0.05,
              ),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image with overlays like home screen
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180, // Fixed height - allows natural aspect ratio
                    child: _buildNetworkOrPlaceholder(theme, context),
                  ),
                ),
                Positioned(top: 12, left: 12, child: _buildStatusBadge(theme)),
                Positioned(top: 12, right: 12, child: _buildActionMenu(theme)),
              ],
            ),
            const SizedBox(height: 10),
            // Two-column layout: Left (Brand, Model, Price, Date) | Right (Year, Mileage, Comments)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand and Model
                      Obx(() {
                        final resolvedBrand = postController.resolveBrandName(
                          (brandId?.isNotEmpty ?? false) ? brandId! : brand,
                        );
                        final _ = postController.modelNameResolutionTick.value;
                        final resolvedModel = postController
                            .resolveModelWithBrand(
                              (modelId?.isNotEmpty ?? false) ? modelId! : model,
                              (brandId?.isNotEmpty ?? false) ? brandId! : brand,
                            );

                        // Helper to check if string looks like UUID
                        bool looksLikeUuid(String s) =>
                            s.length > 16 &&
                            RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(s);

                        final brandText = resolvedBrand.isEmpty
                            ? 'Unknown'
                            : looksLikeUuid(resolvedBrand)
                            ? '...'
                            : resolvedBrand;

                        final modelText = resolvedModel.isEmpty
                            ? ''
                            : looksLikeUuid(resolvedModel)
                            ? '...'
                            : resolvedModel;

                        final title = "$brandText ${modelText}".trim();

                        return Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      const SizedBox(height: 8),
                      // Price
                      Text(
                        "${price.toStringAsFixed(0)} $currency",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: (s == true)
                              ? acceptedGreen
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Posted date
                      Text(
                        'post_card_posted_at'.trParams({
                          'date': _formatDate(createdAt),
                        }),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Year
                    _buildDetailChip(
                      theme,
                      svgAsset: AppImages.car,
                      label: year.toStringAsFixed(0),
                    ),
                    const SizedBox(height: 8),
                    // Mileage
                    _buildDetailChip(
                      theme,
                      icon: Icons.speed_outlined,
                      label: "${milleage.toStringAsFixed(0)} km",
                    ),
                    const SizedBox(height: 8),
                    // Comments (if available)
                    if (status == true &&
                        commentCount != null &&
                        commentCount! > 0)
                      Container(
                        constraints: const BoxConstraints(minWidth: 60),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$commentCount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// REFINED: A reusable chip for displaying car details.
  /// This version is simpler, using a subtle background and secondary color for accent,
  /// feeling more like an informative "pill" than a button.
  Widget _buildDetailChip(
    ThemeData theme, {
    IconData? icon,
    String? svgAsset,
    required String label,
  }) {
    assert(
      icon != null || svgAsset != null,
      'Either an IconData or an svgAsset path must be provided',
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          20,
        ), // More rounded for a pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgAsset != null)
            SvgPicture.asset(
              svgAsset,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.secondary,
                BlendMode.srcIn,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 14, color: theme.colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// APPLE-FRIENDLY REFINEMENT: The status badge now uses a more subtle design.
  /// It pairs a light, transparent background with a stronger text/icon color,
  /// creating a modern look that is less visually jarring.
  Widget _buildStatusBadge(ThemeData theme) {
    // Map nullable status: null -> Pending, true -> Active, false -> Inactive
    final bool? s = status;
    late final String label;
    late final Color contentColor;
    late final IconData icon;
    if (s == null) {
      label = 'post_status_pending'.tr;
      contentColor = Colors.orange.shade600;
      icon = Icons.hourglass_top_rounded;
    } else if (s) {
      label = 'post_status_active'.tr;
      contentColor = Colors.green.shade600;
      icon = Icons.check_circle_outline_rounded;
    } else {
      label = 'post_status_declined'.tr;
      contentColor = theme.colorScheme.error;
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: contentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: contentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: contentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// REFINED: The action menu button is now more subtle.
  Widget _buildActionMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded, // Using a different icon for a softer look
        color: theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: 'post_menu_more_options'.tr,
      position: PopupMenuPosition.under,
      color: theme.colorScheme.surfaceContainerHigh, // Menu background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'Delete') {
          Get.dialog(
            AlertDialog(
              title: Text('post_confirm_deletion_title'.tr),
              content: Text('post_confirm_deletion_message'.tr),
              actions: [
                TextButton(
                  onPressed: () => NavigationUtils.closeGlobal(),
                  child: Text(
                    "Cancel".tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    postController.deleteMyPost(uuid);
                    NavigationUtils.closeGlobal();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Delete".tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'Delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete'.tr,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Navigation now mirrors home/favorites: direct push with raw uuid argument.
  void _navigateToPostDetails(String id) {
    if (Get.isRegistered<PostController>()) {
      // Potential warm-up spot (e.g., prefetch) left intentionally blank.
    }
    Get.to(() => PostDetailsScreen(), arguments: id);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      // Simple dd.MM.yyyy formatting without intl dependency (already imported but avoiding extra overhead)
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d.$m.$y';
    } catch (_) {
      return iso;
    }
  }
}
