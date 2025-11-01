import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';

/// Fullscreen immersive media viewer for post images with adaptive aspect ratio support
/// - Dark backdrop
/// - Swipe between images (PageView)
/// - Pinch zoom & pan (InteractiveViewer)
/// - Overlay controls: Back & Favorite (matching post details style, no AppBar)
/// - Optional hero animation continuity if caller wraps images with same tag pattern
/// - Uses Photo metadata for optimal image quality and caching
class ViewPostPhotoScreen extends StatefulWidget {
  const ViewPostPhotoScreen({
    super.key,
    required this.photos,
    this.currentIndex = 0,
    this.heroGroupTag,
    this.postUuid,
  });

  final List<Photo> photos;
  final int currentIndex;
  final String? heroGroupTag; // to align hero tags with carousel if provided
  final String? postUuid; // for favorite toggle

  @override
  State<ViewPostPhotoScreen> createState() => _ViewPostPhotoScreenState();
}

class _ViewPostPhotoScreenState extends State<ViewPostPhotoScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _index = 0;
  late FavoritesController _favoritesController;
  final Map<int, TransformationController> _zoomControllers = {};
  late final AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  int? _animatingIndex;

  @override
  void initState() {
    super.initState();
    _index = widget.currentIndex.clamp(
      0,
      widget.photos.isEmpty ? 0 : widget.photos.length - 1,
    );
    _pageController = PageController(initialPage: _index);
    // obtain favorites controller
    _favoritesController = Get.put(FavoritesController(), permanent: false);
    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _zoomAnimController.addListener(() {
      if (_animatingIndex != null) {
        final tc = _zoomControllers[_animatingIndex!];
        if (tc != null && _zoomAnimation != null) {
          tc.value = _zoomAnimation!.value;
        }
      }
    });

    // ✅ Precache after widget is built (using post-frame callback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _precacheAdjacentImages(_index);
      }
    });
  }

  /// Precache images adjacent to current index for smooth swiping with adaptive dimensions
  void _precacheAdjacentImages(int currentIndex) {
    if (widget.photos.isEmpty || !mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Precache next image
    if (currentIndex + 1 < widget.photos.length) {
      final photo = widget.photos[currentIndex + 1];
      final rawPath = photo.bestPath;

      if (rawPath.isNotEmpty) {
        final normalizedPath = rawPath.replaceAll('\\', '/');

        final cleanBaseUrl = ApiKey.ip.endsWith('/')
            ? ApiKey.ip.substring(0, ApiKey.ip.length - 1)
            : ApiKey.ip;
        final cleanPath = normalizedPath.startsWith('/')
            ? normalizedPath
            : '/$normalizedPath';
        final nextImageUrl = '$cleanBaseUrl$cleanPath';

        // Use adaptive dimensions based on photo's aspect ratio
        final dimensions = _calculateAdaptiveDimensions(
          photo,
          screenWidth,
          screenHeight,
        );

        precacheImage(
          CachedNetworkImageProvider(
            nextImageUrl,
            maxWidth: dimensions.$1,
            maxHeight: dimensions.$2,
          ),
          context,
        ).catchError((e) {
          debugPrint('[ViewPostPhoto] ❌ Failed to precache next: $e');
        });
      }
    }

    // Precache previous image
    if (currentIndex - 1 >= 0) {
      final photo = widget.photos[currentIndex - 1];
      final rawPath = photo.bestPath;

      if (rawPath.isNotEmpty) {
        final normalizedPath = rawPath.replaceAll('\\', '/');

        final cleanBaseUrl = ApiKey.ip.endsWith('/')
            ? ApiKey.ip.substring(0, ApiKey.ip.length - 1)
            : ApiKey.ip;
        final cleanPath = normalizedPath.startsWith('/')
            ? normalizedPath
            : '/$normalizedPath';
        final prevImageUrl = '$cleanBaseUrl$cleanPath';

        // Use adaptive dimensions based on photo's aspect ratio
        final dimensions = _calculateAdaptiveDimensions(
          photo,
          screenWidth,
          screenHeight,
        );

        precacheImage(
          CachedNetworkImageProvider(
            prevImageUrl,
            maxWidth: dimensions.$1,
            maxHeight: dimensions.$2,
          ),
          context,
        ).catchError((e) {
          debugPrint('[ViewPostPhoto] ❌ Failed to precache prev: $e');
        });
      }
    }
  }

  /// Calculate adaptive cache dimensions based on photo metadata and screen size
  (int, int) _calculateAdaptiveDimensions(
    Photo photo,
    double screenWidth,
    double screenHeight,
  ) {
    // Use ratio from photo metadata if available
    if (photo.ratio != null && photo.ratio! > 0) {
      final ratio = photo.ratio!;
      double width = screenWidth;
      double height = width / ratio;

      if (height > screenHeight) {
        height = screenHeight;
        width = height * ratio;
      }

      // 6x multiplier for high quality
      return ((width * 6).toInt(), (height * 6).toInt());
    }

    // Fallback to aspect ratio string
    switch (photo.aspectRatio) {
      case '16:9':
        return (screenWidth > screenHeight)
            ? ((screenWidth * 6).toInt(), (screenWidth * 6 / 16 * 9).toInt())
            : ((screenHeight * 16 / 9 * 6).toInt(), (screenHeight * 6).toInt());
      case '4:3':
        return (screenWidth > screenHeight)
            ? ((screenWidth * 6).toInt(), (screenWidth * 6 / 4 * 3).toInt())
            : ((screenHeight * 4 / 3 * 6).toInt(), (screenHeight * 6).toInt());
      case '1:1':
        final size = screenWidth < screenHeight ? screenWidth : screenHeight;
        return ((size * 6).toInt(), (size * 6).toInt());
      case '9:16':
        return (screenWidth > screenHeight)
            ? ((screenHeight * 9 / 16 * 6).toInt(), (screenHeight * 6).toInt())
            : ((screenWidth * 6).toInt(), (screenWidth * 6 / 9 * 16).toInt());
      default:
        // Default 4:3 ratio
        return ((screenWidth * 6).toInt(), (screenWidth * 6 / 4 * 3).toInt());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _zoomAnimController.dispose();
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TransformationController _getTc(int i) {
    return _zoomControllers.putIfAbsent(i, () => TransformationController());
  }

  void _handleDoubleTap(int i) {
    final tc = _getTc(i);
    final isZoomed = tc.value != Matrix4.identity();
    final begin = tc.value.clone();
    final end = isZoomed
        ? Matrix4.identity()
        : (Matrix4.identity()..scale(2.0));
    _animatingIndex = i;
    _zoomAnimation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _zoomAnimController, curve: Curves.easeOutCubic),
    );
    _zoomAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = widget.photos;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView with zoomable images using adaptive display
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              // Precache adjacent when swiping
              _precacheAdjacentImages(i);
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (ctx, i) {
              final photo = photos[i];
              final tc = _getTc(i);
              return _FullscreenImageItem(
                key: PageStorageKey('fullscreen_img_$i'),
                photo: photo,
                index: i,
                heroTag:
                    'post-media-${widget.heroGroupTag ?? hashCode}-$i-${photo.bestPath.hashCode}',
                onDoubleTap: () => _handleDoubleTap(i),
                transformationController: tc,
                screenWidth: screenSize.width,
                screenHeight: screenSize.height,
              );
            },
          ),

          // Top overlay controls
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
                        final isFav =
                            uuid != null &&
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

          // Bottom index indicator
          if (photos.length > 1)
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
                    '${_index + 1} / ${photos.length}',
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

/// Fullscreen image item with AutomaticKeepAliveClientMixin and adaptive aspect ratio
/// to prevent disposal and keep images cached when swiping
class _FullscreenImageItem extends StatefulWidget {
  final Photo photo;
  final int index;
  final String heroTag;
  final VoidCallback onDoubleTap;
  final TransformationController transformationController;
  final double screenWidth;
  final double screenHeight;

  const _FullscreenImageItem({
    super.key,
    required this.photo,
    required this.index,
    required this.heroTag,
    required this.onDoubleTap,
    required this.transformationController,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<_FullscreenImageItem> createState() => _FullscreenImageItemState();
}

class _FullscreenImageItemState extends State<_FullscreenImageItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Keep widget alive!

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: InteractiveViewer(
        transformationController: widget.transformationController,
        panEnabled: true,
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: Hero(
            tag: widget.heroTag,
            flightShuttleBuilder: (c, anim, dir, from, to) => to.widget,
            // ✅ Use adaptive dimensions based on photo aspect ratio metadata
            child: CachedImageHelper.buildAdaptivePostImage(
              photo: widget.photo,
              baseUrl: ApiKey.ip,
              containerWidth: widget.screenWidth,
              containerHeight: widget.screenHeight,
              fit: BoxFit.contain,
              isThumbnail: false, // 6x multiplier for high quality
            ),
          ),
        ),
      ),
    );
  }
}
