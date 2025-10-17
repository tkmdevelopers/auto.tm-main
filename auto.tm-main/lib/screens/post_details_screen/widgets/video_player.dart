import 'package:auto_tm/screens/post_details_screen/controller/video_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:chewie/chewie.dart';

// class VideoPlayerPage extends GetView<FullVideoPlayerController> {
class VideoPlayerPage extends StatelessWidget {
  VideoPlayerPage({super.key});

  // We intentionally do not eagerly create controller before we parse arguments.
  final FullVideoPlayerController controller = Get.put(FullVideoPlayerController());
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use PopScope (WillPopScope deprecated) to handle back navigation & predictive back.
    return PopScope(
      canPop: true, // allow default pop after our cleanup
      onPopInvokedWithResult: (didPop, result) {
        // Always dispose video resources; if gesture already popped, we just clean up.
        controller.disposeVideo();
        // If the pop wasn't performed (e.g., programmatic cancellation), perform it.
        if (!didPop) {
          NavigationUtils.close(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 4,
          surfaceTintColor: theme.appBarTheme.backgroundColor,
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Text('post_video_play_title'.tr),
          leading: IconButton(
            onPressed: () {
              controller.disposeVideo();
              NavigationUtils.close(context);
            },
            icon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
          ),
        ),
        body: Center(
          child: Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: controller.isLoading,
                  builder: (context, isLoadingValue, _) {
                    if (isLoadingValue) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ValueListenableBuilder<String?>(
                      valueListenable: controller.errorMessage,
                      builder: (context, errorMessageValue, _) {
                        if (errorMessageValue != null) {
                          return Text(
                            'post_video_play_error'.trParams({'error': errorMessageValue}),
                          );
                        }
                        return ValueListenableBuilder<bool>(
                          valueListenable: controller.isEmpty,
                          builder: (context, isEmptyValue, _) {
                            if (isEmptyValue) {
                              return Text('post_video_missing_url'.tr);
                            }
                            return controller.chewieController != null &&
                                    controller
                                        .chewieController!
                                        .videoPlayerController
                                        .value
                                        .isInitialized
                                ? AspectRatio(
                                    aspectRatio:
                                        controller
                                            .chewieController!
                                            .aspectRatio ??
                                        controller
                                            .chewieController!
                                            .videoPlayerController
                                            .value
                                            .aspectRatio,
                                    child: Chewie(
                                      controller: controller.chewieController!,
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
