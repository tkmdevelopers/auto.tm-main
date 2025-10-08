import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// class FullVideoPlayerController extends GetxController {
//   ChewieController? chewieController;
//   String videoUrl = '';
//   final String apiKeyIp = ApiKey.ip;
//   final ValueNotifier<bool> isLoading = ValueNotifier(false);
//   final ValueNotifier<String?> errorMessage = ValueNotifier(null);
//   final ValueNotifier<bool> isEmpty = ValueNotifier(false);

//   @override
//   void onInit() {
//     super.onInit();
//     final String? url = Get.arguments as String?;
//     if (url != null && url.isNotEmpty) {
//       videoUrl = '$apiKeyIp$url';
//       _playVideo();
//       isEmpty.value = false;
//     } else {
//       isEmpty.value = true;
//     }
//   }

//   Future<void> _playVideo() async {
//     isLoading.value = true;
//     errorMessage.value = null;

//     final videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
//     try {
//       await videoPlayerController.initialize();
//       chewieController = ChewieController(
//         videoPlayerController: videoPlayerController,
//         autoPlay: true,
//         looping: false, // Зацикливаем воспроизведение одного видео
//         showControls: true,
//         aspectRatio: videoPlayerController.value.aspectRatio,
//         errorBuilder: (context, errorMessage) {
//           return Center(
//             child: Text('Ошибка воспроизведения: $errorMessage'),
//           );
//         },
//       );
//       isLoading.value = false;
//     } catch (e) {
//       isLoading.value = false;
//       errorMessage.value = e.toString();
//     }
//   }

//   // @override
//   // void onClose() {
//   //   chewieController?.dispose();
//   //   isLoading.dispose();
//   //   errorMessage.dispose();
//   //   isEmpty.dispose();
//   //   super.onClose();
//   // }

//   // void disposeVideo() {
//   //   chewieController?.dispose();
//   //   chewieController = null;
//   // }
//   @override
// void onClose() {
//   disposeVideo(); // Clean up video
//   super.onClose();
// }

// void disposeVideo() {
//   chewieController?.dispose();
//   // videoPlayerController?.dispose(); // if you're managing it separately
//   chewieController = null;
// }
// }

class FullVideoPlayerController extends GetxController {
  ChewieController? chewieController;
  VideoPlayerController? videoPlayerController; // Store it here
  String videoUrl = '';
  final String apiKeyIp = ApiKey.ip;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<bool> isEmpty = ValueNotifier(false);

  @override
  void onInit() {
    super.onInit();
    final String? url = Get.arguments as String?;
    if (url != null && url.isNotEmpty) {
      videoUrl = '$apiKeyIp$url';
      _playVideo();
      isEmpty.value = false;
    } else {
      isEmpty.value = true;
    }
  }

  Future<void> _playVideo() async {
    isLoading.value = true;
    errorMessage.value = null;

    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await videoPlayerController!.initialize();
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        aspectRatio: videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text('Ошибка воспроизведения: $errorMessage'),
          );
        },
      );
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
    }
  }

  void disposeVideo() {
    chewieController?.dispose();
    videoPlayerController?.dispose(); // Dispose the video controller too
    chewieController = null;
    videoPlayerController = null;
  }

  @override
  void onClose() {
    disposeVideo(); // Ensure everything is cleaned
    isLoading.dispose();
    errorMessage.dispose();
    isEmpty.dispose();
    super.onClose();
  }
}
