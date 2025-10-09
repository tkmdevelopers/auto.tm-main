import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';

/// Unified media carousel for post details: images (and optional video button overlay)
class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({
    super.key,
    required this.photoPaths,
    required this.onIndexChanged,
    this.initialIndex = 0,
    this.onBack,
    this.onToggleFavorite,
    this.isFavorite = false,
    this.onOpenFullScreen,
    this.videoUrl,
    this.onOpenVideo,
  });

  final List<String> photoPaths;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback? onBack;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;
  final VoidCallback? onOpenFullScreen;
  final String? videoUrl; // optional single video path
  final VoidCallback? onOpenVideo;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  late final PageController _pageController;
  int _index = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photoPaths.isEmpty ? 0 : widget.photoPaths.length - 1);
    _pageController = PageController(initialPage: _index, viewportFraction: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final path in widget.photoPaths.take(4)) {
        if (path.isNotEmpty) {
          precacheImage(NetworkImage('${ApiKey.ip}$path'), context).ignore();
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = widget.photoPaths;
    final hasImages = photos.isNotEmpty;
    final aspect = 16 / 9; // fixed for consistency; could be dynamic based on first image metadata later
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop (subtle tonal surface if empty)
            if (!hasImages)
              Container(color: theme.colorScheme.surfaceVariant.withOpacity(.4)),

            if (hasImages)
              PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _index = i);
                  widget.onIndexChanged(i);
                  // Precache next/prev for smoother swipes
                  final ahead = i + 1;
                  if (ahead < photos.length) {
                    precacheImage(NetworkImage('${ApiKey.ip}${photos[ahead]}'), context).ignore();
                  }
                },
                itemCount: photos.length,
                itemBuilder: (context, i) {
                  final path = photos[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onOpenFullScreen,
                    child: Hero(
                      tag: 'post-media-$i-${path.hashCode}',
                      flightShuttleBuilder: (ctx, anim, dir, from, to) => to.widget,
                      child: _NetworkImageTile(path: path),
                    ),
                  );
                },
              ),

            // Top bar (back + favorite)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Back',
                    onTap: widget.onBack,
                    theme: theme,
                  ),
                  _CircleButton(
                    icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    tooltip: 'Favorite',
                    onTap: widget.onToggleFavorite,
                    color: widget.isFavorite ? Colors.redAccent : theme.colorScheme.primary,
                    theme: theme,
                  ),
                ],
              ),
            ),

            // Gradient bottom overlay for legibility of indicators/buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(.38),
                        Colors.black.withOpacity(.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Page indicator (center bottom)
            if (hasImages)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(.72),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(.4),
                        width: 0.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_index + 1} / ${photos.length}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),

            // Video chip (bottom right) if video present
            if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 12,
                child: _VideoChip(
                  onTap: widget.onOpenVideo,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NetworkImageTile extends StatelessWidget {
  const _NetworkImageTile({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (path.isEmpty) {
      return _PlaceholderTile(icon: Icons.image_not_supported_outlined);
    }
    return Image.network(
      '${ApiKey.ip}$path',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _LoadingSkeleton(progress: progress,); // skeleton
      },
      errorBuilder: (context, error, stackTrace) => _PlaceholderTile(
        icon: Icons.broken_image_outlined,
        color: theme.colorScheme.error.withOpacity(.7),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({this.progress});
  final ImageChunkEvent? progress;
  @override
  Widget build(BuildContext context) {
    final pct = progress?.expectedTotalBytes != null && progress!.expectedTotalBytes! > 0
        ? (progress!.cumulativeBytesLoaded / progress!.expectedTotalBytes!).clamp(0, 1)
        : null;
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surfaceVariant.withOpacity(.55),
                  theme.colorScheme.surfaceVariant.withOpacity(.25),
                ],
              ),
            )),
        if (pct != null)
          Center(
            child: SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                value: pct.toDouble(),
              ),
            ),
          )
        else
          const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
      ],
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.icon, this.color});
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(.35),
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: color ?? theme.colorScheme.onSurfaceVariant.withOpacity(.6),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.theme,
    this.color,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final ThemeData theme;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface.withOpacity(.72),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(
            icon,
            size: 22,
            color: color ?? theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _VideoChip extends StatelessWidget {
  const _VideoChip({this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF1E4EED),
              Color(0xFF7FA7F6),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Video',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
