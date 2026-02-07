import 'package:auto_tm/utils/image_url_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';

/// Fullscreen immersive media viewer for post images.
/// Uses [photo_view] PhotoViewGallery for zoom, pan, and page swipe with gesture handling.
/// - Dark backdrop; swipe between images when at 1x; pan when zoomed.
/// - Overlay: Back and Favorite. Bottom index when multiple images.
/// - Hero tags align with carousel for transition continuity.
class ViewPostPhotoScreen extends StatefulWidget {
  const ViewPostPhotoScreen({
    super.key,
    required this.imageUrls,
    this.currentIndex = 0,
    this.heroGroupTag,
    this.postUuid,
  });

  final List<String> imageUrls;
  final int currentIndex;
  final String? heroGroupTag;
  final String? postUuid;

  @override
  State<ViewPostPhotoScreen> createState() => _ViewPostPhotoScreenState();
}

class _ViewPostPhotoScreenState extends State<ViewPostPhotoScreen> {
  late final PageController _pageController;
  int _index = 0;
  late FavoritesController _favoritesController;
  bool _currentPageZoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.currentIndex.clamp(0, widget.imageUrls.isEmpty ? 0 : widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _index);
    _favoritesController = Get.put(FavoritesController(), permanent: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.imageUrls;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: _pageController,
            onPageChanged: (i) {
              setState(() {
                _index = i;
                _currentPageZoomed = false;
              });
            },
            scaleStateChangedCallback: (PhotoViewScaleState state) {
              setState(() {
                _currentPageZoomed = state == PhotoViewScaleState.zoomedIn ||
                    state == PhotoViewScaleState.originalSize;
              });
            },
            scrollPhysics: _currentPageZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) {
              final size = MediaQuery.sizeOf(context);
              return Shimmer.fromColors(
                baseColor: theme.colorScheme.surfaceContainerHighest,
                highlightColor: theme.colorScheme.surface,
                child: Container(
                  width: size.width,
                  height: size.height,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
                ),
              );
            },
            builder: (context, index) {
              final path = images[index];
              final url = fullImageUrl(ApiKey.ip, path);
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(url),
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'post-media-${widget.heroGroupTag ?? hashCode}-$index-${path.hashCode}',
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.5,
                initialScale: PhotoViewComputedScale.contained,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _OverlayButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Back'.tr,
                    onTap: () => NavigationUtils.close(context),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final uuid = widget.postUuid;
                        final isFav = uuid != null &&
                            _favoritesController.favorites.contains(uuid);
                        return _OverlayButton(
                          icon: isFav ? Icons.favorite : Icons.favorite_border,
                          tooltip: 'Favorite'.tr,
                          color: isFav
                              ? Colors.redAccent
                              : theme.colorScheme.primary,
                          onTap: uuid == null
                              ? null
                              : () => _favoritesController.toggleFavorite(uuid),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (images.length > 1)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24, width: .8),
                  ),
                  child: Text(
                    '${_index + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: tooltip,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Icon(icon, color: color ?? Colors.white, size: 22),
        ),
      ),
    );
  }
}
