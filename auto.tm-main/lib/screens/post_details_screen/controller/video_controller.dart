import 'package:auto_tm/utils/key.dart';
import 'package:flutter/foundation.dart';
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
    final args = Get.arguments;
    if (kDebugMode) debugPrint('[VideoController] raw args: $args');
    // Accept either a single relative path string OR a List<String> of fully-qualified or relative paths (first one plays now).
    String? resolved;
    String joinBase(String pathPart) {
      final base = apiKeyIp.endsWith('/')
          ? apiKeyIp.substring(0, apiKeyIp.length - 1)
          : apiKeyIp;
      return base + pathPart; // pathPart already begins with '/'
    }

    String normalize(String raw) {
      if (raw.isEmpty) return raw;
      // If already absolute http(s)
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
      // If starts with /media it is already served path, just prefix domain (ensure no duplicate slashes)
      if (raw.startsWith('/media/')) {
        return joinBase(raw);
      }
      // If looks like a publicUrl property accidentally passed without leading slash
      if (raw.startsWith('media/')) {
        return joinBase('/$raw');
      }
      // If backend relative (e.g., video/xyz.mp4 or uploads/video/xyz.mp4)
      // Strip leading 'uploads/' because backend exposes /media root
      var cleaned = raw;
      cleaned = cleaned.replaceFirst(RegExp(r'^/+'), '');
      if (cleaned.startsWith('uploads/')) {
        cleaned = cleaned.substring('uploads/'.length);
      }
      // Build /media/<cleaned>
      return joinBase('/media/$cleaned');
    }

    if (args is List) {
      // Choose first non-empty element
      for (final element in args) {
        if (element is String && element.trim().isNotEmpty) {
          resolved = element;
          break;
        }
      }
    } else if (args is String) {
      resolved = args;
    }
    if (resolved != null && resolved.isNotEmpty) {
      videoUrl = normalize(resolved);
      if (kDebugMode) {
        debugPrint(
          '[VideoController] resolved: $resolved => videoUrl: $videoUrl',
        );
      }
      _playVideo();
      isEmpty.value = false;
    } else {
      if (kDebugMode) {
        debugPrint('[VideoController] No valid video argument provided');
      }
      isEmpty.value = true;
    }
  }

  Future<void> _playVideo() async {
    isLoading.value = true;
    errorMessage.value = null;

    if (kDebugMode) {
      debugPrint('[VideoController] Initializing player with: $videoUrl');
    }
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );
    try {
      await videoPlayerController!.initialize();
      if (kDebugMode) {
        debugPrint(
          '[VideoController] Initialization success. AspectRatio=${videoPlayerController!.value.aspectRatio}',
        );
      }
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        aspectRatio: videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) => Center(
          child: Text(
            'post_video_play_error'.trParams({'error': errorMessage}),
          ),
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[VideoController] Player ready. Duration=${videoPlayerController!.value.duration}',
        );
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      if (kDebugMode) debugPrint('[VideoController][ERROR] $e');
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
