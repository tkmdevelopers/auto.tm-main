import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';

class PostMediaScrollableSelectionWidget extends StatelessWidget {
  const PostMediaScrollableSelectionWidget({super.key});

  static const double _tileHeight = 140;
  static const double _spacing = 14;
  static const int _maxPhotos = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final PostController postController = Get.find<PostController>();
    final double tileWidth = MediaQuery.of(context).size.width * 0.3;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: _tileHeight,
        child: Obx(() {
          final photos = postController.selectedImages;
          final hasVideo = postController.selectedVideo.value != null;

          // Order: all photos -> add photo button (if room) -> video tile (always last)
          final int photoCount = photos.length;
          final bool canAddPhoto = photoCount < _maxPhotos;
          // total = photos + (addPhoto?1:0) + 1 video tile
          final int totalItems = photoCount + (canAddPhoto ? 1 : 0) + 1;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: totalItems,
            separatorBuilder: (_, _) => const SizedBox(width: _spacing),
            itemBuilder: (context, index) {
              // Photos occupy [0 .. photoCount-1]
              if (index < photoCount) {
                return _PhotoTile(
                  bytes: photos[index],
                  width: tileWidth,
                  onRemove: () => postController.removeImage(index),
                );
              }

              // Add photo button at position photoCount (if allowed)
              if (canAddPhoto && index == photoCount) {
                return _AddPhotoTile(
                  width: tileWidth,
                  onTap: () => postController.pickImages(),
                  current: photoCount,
                  max: _maxPhotos,
                );
              }

              // Video tile is always last
              return _VideoTile(
                width: tileWidth,
                controller: postController,
                theme: theme,
                hasVideo: hasVideo,
              );
            },
          );
        }),
      ),
    );
  }
}

class _BaseTile extends StatelessWidget {
  final double width;
  final Widget child;
  const _BaseTile({required this.width, required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: PostMediaScrollableSelectionWidget._tileHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 0.6, color: AppColors.textTertiaryColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final double width;
  final VoidCallback onTap;
  final int current;
  final int max;
  const _AddPhotoTile({
    required this.width,
    required this.onTap,
    required this.current,
    required this.max,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _BaseTile(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 30,
              color: AppColors.textTertiaryColor,
            ),
            const SizedBox(height: 6),
            Text(
              'Add photo'.tr,
              style: TextStyle(
                color: AppColors.textTertiaryColor,
                fontSize: 12,
              ),
            ),
            Text(
              '$current/$max',
              style: TextStyle(
                color: AppColors.textTertiaryColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Uint8List bytes;
  final double width;
  final VoidCallback onRemove;
  const _PhotoTile({
    required this.bytes,
    required this.width,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BaseTile(
          width: width,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  final double width;
  final PostController controller;
  final ThemeData theme;
  final bool hasVideo;
  const _VideoTile({
    required this.width,
    required this.controller,
    required this.theme,
    required this.hasVideo,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.pickVideo(),
      child: Stack(
        children: [
          _BaseTile(
            width: width,
            child: Obx(() {
              // Rebuild on video state / thumbnail changes
              final vc = controller.videoPlayerController;
              final thumb = controller.videoThumbnail.value;
              final initialized =
                  controller.isVideoInitialized.value &&
                  vc != null &&
                  vc.value.isInitialized;

              if (!hasVideo) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 26,
                      color: AppColors.textTertiaryColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add video'.tr,
                      style: TextStyle(
                        color: AppColors.textTertiaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }

              if (!initialized && thumb != null) {
                // Show thumbnail plus compression progress (if active)
                final isCompressing = controller.isCompressingVideo.value;
                final progress = controller.videoCompressionProgress.value;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(thumb, fit: BoxFit.cover),
                    ),
                    if (isCompressing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 54,
                            height: 54,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress.clamp(0, 1),
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.secondary,
                                  ),
                                  backgroundColor: Colors.white24,
                                ),
                                Text(
                                  '${(progress * 100).clamp(0, 99.9).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const Positioned(
                        bottom: 6,
                        right: 6,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                );
              }

              if (!initialized) {
                final isCompressing = controller.isCompressingVideo.value;
                final progress = controller.videoCompressionProgress.value;
                return Center(
                  child: isCompressing
                      ? SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress.clamp(0, 1),
                                strokeWidth: 5,
                              ),
                              Text(
                                '${(progress * 100).clamp(0, 99.9).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const CircularProgressIndicator(strokeWidth: 2),
                );
              }

              return GestureDetector(
                onTap: () {
                  if (vc.value.isPlaying) {
                    vc.pause();
                  } else {
                    vc.play();
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: vc.value.size.width,
                          height: vc.value.size.height,
                          child: VideoPlayer(vc),
                        ),
                      ),
                    ),
                    if (!vc.value.isPlaying)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          if (hasVideo)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => controller.disposeVideo(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
