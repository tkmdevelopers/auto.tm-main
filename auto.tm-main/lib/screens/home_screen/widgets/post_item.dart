import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/post_details_screen.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class PostItem extends StatelessWidget {
  final String uuid;
  final String model;
  final String brand;
  final double price;
  final String photoPath;
  final String? subscription;
  final String location;
  final String region;
  final double year;
  final double milleage;
  final String currency;
  final String createdAt;
  /// Passed from parent so one Obx at list level drives updates (fewer rebuilds).
  final bool isFav;

  PostItem({
    super.key,
    required this.uuid,
    required this.model,
    required this.brand,
    required this.price,
    required this.photoPath,
    this.subscription,
    required this.year,
    required this.milleage,
    required this.currency,
    required this.createdAt,
    required this.location,
    this.region = 'Local',
    this.isFav = false,
  });

  FavoritesController get _favoritesController => Get.find<FavoritesController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Get.to(() => PostDetailsScreen(), arguments: uuid),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
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
            imageUrl: photoPath.isNotEmpty
                ? '${ApiKey.ip}$photoPath'
                : 'https://placehold.co/400x250',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              width: double.infinity,
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              width: double.infinity,
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
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
        if (subscription != null)
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
            onTap: () => _favoritesController.toggleFavorite(uuid),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1.2,
                ),
                boxShadow: isFav
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
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
                        : theme.colorScheme.onSurface.withOpacity(0.7),
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
            '$brand $model',
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
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            year.toInt().toString(),
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
    // Unified logic with details screen:
    // If region == Local -> show location (city) if non-empty.
    // If region == UAE or China -> show region label.
    // Otherwise hide location/region info.
    String regionTrim = region.trim();
    String locTrim = location.trim();
    final lower = regionTrim.toLowerCase();
    String? displayLocation;
    if (lower == 'local') {
      if (locTrim.isNotEmpty) displayLocation = locTrim;
    } else if (lower == 'uae' || lower == 'china') {
      displayLocation = regionTrim; // already correct
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '${price.toStringAsFixed(0)} $currency',
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
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                displayLocation,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // _shouldShowRegion removed: region is displayed only for non-local posts now.

  // Removed standalone region row; region now integrated into price/location area (only when non-local).

  Widget _buildDetailsRow(ThemeData theme) {
    return Row(
      children: [
        _buildDetailItem(
          theme,
          Icons.speed,
          '${milleage.toStringAsFixed(0)} km',
        ),
        const SizedBox(width: 16),
        _buildDetailItem(theme, Icons.access_time, _formatDate(createdAt)),
      ],
    );
  }

  Widget _buildDetailItem(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
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
