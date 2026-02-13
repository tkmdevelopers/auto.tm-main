import 'package:auto_tm/domain/models/post_extensions.dart';
import 'package:auto_tm/domain/models/post.dart' as domain;
import 'package:auto_tm/utils/color_extensions.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/post_details_screen.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class PostItem extends StatelessWidget {
  final domain.Post post;

  /// Passed from parent so one Obx at list level drives updates (fewer rebuilds).
  final bool isFav;

  const PostItem({
    super.key,
    required this.post,
    this.isFav = false,
  });

  FavoritesController get _favoritesController =>
      Get.find<FavoritesController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Get.to(() => PostDetailsScreen(), arguments: post.uuid),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.opacityCompat(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Favorite Button & Premium Badge
            _buildImageSection(theme),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(theme),
                  const SizedBox(height: 8),
                  _buildPriceLocationRow(theme),
                  const SizedBox(height: 12),
                  _buildDetailsRow(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Stack(
      children: [
        // Car Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: CachedNetworkImage(
            imageUrl: post.photoPath.isNotEmpty
                ? '${ApiKey.ip}${post.photoPath}'
                : 'https://placehold.co/400x250',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            fadeInCurve: Curves.easeOut,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              highlightColor: theme.colorScheme.surface,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppImages.defaultImageSvg,
                  height: 40,
                  width: 40,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Premium Badge
        if (post.subscription != null)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Favorite button: isFav passed from parent (one Obx at list level).
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _favoritesController.toggleFavorite(post.uuid),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.opacityCompat(0.1),
                  width: 1.2,
                ),
                boxShadow: isFav
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.opacityCompat(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey<bool>(isFav),
                    color: isFav
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.opacityCompat(0.7),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${post.brand} ${post.model}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.opacityCompat(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            post.yearString,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceLocationRow(ThemeData theme) {
    String regionTrim = post.region.trim();
    String locTrim = post.location.trim();
    final lower = regionTrim.toLowerCase();
    String? displayLocation;
    if (lower == 'local') {
      if (locTrim.isNotEmpty) displayLocation = locTrim;
    } else if (lower == 'uae' || lower == 'china') {
      displayLocation = regionTrim;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            post.priceWithCurrency,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.notificationColor,
            ),
          ),
        ),
        if (displayLocation != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                lower == 'local' ? Icons.location_on_outlined : Icons.public,
                size: 14,
                color: theme.colorScheme.onSurface.opacityCompat(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                displayLocation,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.opacityCompat(0.6),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailsRow(ThemeData theme) {
    return Row(
      children: [
        _buildDetailItem(
          theme,
          Icons.speed,
          post.formattedMilleage,
        ),
        const SizedBox(width: 16),
        _buildDetailItem(theme, Icons.access_time, _formatDate(post.createdAt)),
      ],
    );
  }

  Widget _buildDetailItem(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.opacityCompat(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.opacityCompat(0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Recently';
    }
  }
}
