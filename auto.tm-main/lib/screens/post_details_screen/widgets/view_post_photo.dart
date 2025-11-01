import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';

/// Fullscreen immersive media viewer for post images
/// - Dark backdrop
/// - Swipe between images (PageView)
/// - Pinch zoom & pan (InteractiveViewer)
/// - Overlay controls: Back & Favorite (matching post details style, no AppBar)
/// - Optional hero animation continuity if caller wraps images with same tag pattern
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
      widget.imageUrls.isEmpty ? 0 : widget.imageUrls.length - 1,
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

    // ✅ FIX: Precache after widget is built (using post-frame callback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _precacheAdjacentImages(_index);
      }
    });
  }

  /// Precache images adjacent to current index for smooth swiping
  void _precacheAdjacentImages(int currentIndex) {
    if (widget.imageUrls.isEmpty || !mounted) return;

    // Precache next image
    if (currentIndex + 1 < widget.imageUrls.length) {
      final rawPath = widget.imageUrls[currentIndex + 1];
      final normalizedPath = rawPath.replaceAll('\\', '/');

      final cleanBaseUrl = ApiKey.ip.endsWith('/')
          ? ApiKey.ip.substring(0, ApiKey.ip.length - 1)
          : ApiKey.ip;
      final cleanPath = normalizedPath.startsWith('/')
          ? normalizedPath
          : '/$normalizedPath';
      final nextImageUrl = '$cleanBaseUrl$cleanPath';

      // ✅ Use SAME dimensions as display (800x600 -> 4800x3600)
      precacheImage(
        CachedNetworkImageProvider(
          nextImageUrl,
          maxWidth: 4800,
          maxHeight: 3600,
        ),
        context,
      ).catchError((e) {
        debugPrint('[ViewPostPhoto] ❌ Failed to precache next: $e');
      });
    }

    // Precache previous image
    if (currentIndex - 1 >= 0) {
      final rawPath = widget.imageUrls[currentIndex - 1];
      final normalizedPath = rawPath.replaceAll('\\', '/');

      final cleanBaseUrl = ApiKey.ip.endsWith('/')
          ? ApiKey.ip.substring(0, ApiKey.ip.length - 1)
          : ApiKey.ip;
      final cleanPath = normalizedPath.startsWith('/')
          ? normalizedPath
          : '/$normalizedPath';
      final prevImageUrl = '$cleanBaseUrl$cleanPath';

      precacheImage(
        CachedNetworkImageProvider(
          prevImageUrl,
          maxWidth: 4800,
          maxHeight: 3600,
        ),
        context,
      ).catchError((e) {
        debugPrint('[ViewPostPhoto] ❌ Failed to precache prev: $e');
      });
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
    final images = widget.imageUrls;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView with zoomable images
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              // ✅ FIX: Precache adjacent when swiping
              _precacheAdjacentImages(i);
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (ctx, i) {
              final path = images[i];
              final tc = _getTc(i);
              return _FullscreenImageItem(
                key: PageStorageKey('fullscreen_img_$i'),
                path: path,
                index: i,
                heroTag:
                    'post-media-${widget.heroGroupTag ?? hashCode}-$i-${path.hashCode}',
                onDoubleTap: () => _handleDoubleTap(i),
                transformationController: tc,
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

/// Fullscreen image item with AutomaticKeepAliveClientMixin
/// to prevent disposal and keep images cached when swiping
class _FullscreenImageItem extends StatefulWidget {
  final String path;
  final int index;
  final String heroTag;
  final VoidCallback onDoubleTap;
  final TransformationController transformationController;

  const _FullscreenImageItem({
    super.key,
    required this.path,
    required this.index,
    required this.heroTag,
    required this.onDoubleTap,
    required this.transformationController,
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
            // ✅ FIX: Use SAME dimensions as carousel (800x600 -> 4800x3600)
            child: CachedImageHelper.buildPostImage(
              photoPath: widget.path,
              baseUrl: ApiKey.ip,
              width: 800, // Same as carousel!
              height: 600, // Same as carousel!
              fit: BoxFit.contain,
              isThumbnail: false, // 6x multiplier = 4800x3600
            ),
          ),
        ),
      ),
    );
  }
}
