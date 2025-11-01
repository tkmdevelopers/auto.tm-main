import 'dart:convert';

import 'package:auto_tm/screens/post_details_screen/controller/video_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/video_player.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PostDetailsController extends GetxController {
  final box = GetStorage();

  var post = Rxn<Post>();
  var isLoading = true.obs;
  var currentPage = 0.obs;

  void setCurrentPage(int index) {
    currentPage.value = index;
    // Precache adjacent images when page changes
    _precacheAdjacentImages(index);
  }

  /// Precache first 3 images when post loads for instant carousel navigation
  /// Uses same URL normalization and cache parameters as carousel
  void _precacheInitialImages() {
    final photos = post.value?.photoPaths;
    if (photos == null || photos.isEmpty) return;

    final context = Get.context;
    if (context == null) return;

    // Precache first 3 images (or less if there aren't 3)
    final imagesToPrecache = photos.length > 3 ? 3 : photos.length;
    for (int i = 0; i < imagesToPrecache; i++) {
      // ✅ FIX: Normalize path BEFORE constructing URL (matching cached_image_helper.dart)
      final rawPath = photos[i];
      final normalizedPath = rawPath.replaceAll('\\', '/');

      // Construct URL same way as CachedImageHelper
      final cleanBaseUrl = ApiKey.ip.endsWith('/')
          ? ApiKey.ip.substring(0, ApiKey.ip.length - 1)
          : ApiKey.ip;
      final cleanPath = normalizedPath.startsWith('/')
          ? normalizedPath
          : '/$normalizedPath';
      final imageUrl = '$cleanBaseUrl$cleanPath';

      if (kDebugMode) {
        debugPrint('[PostDetailsController] 🔄 Precaching image $i: $imageUrl');
      }

      // Use same dimensions as carousel (800x600 display, 4800x3600 cached)
      precacheImage(
        CachedNetworkImageProvider(imageUrl, maxWidth: 4800, maxHeight: 3600),
        context,
      ).catchError((e) {
        if (kDebugMode) {
          debugPrint(
            '[PostDetailsController] ❌ Precache failed for image $i: $e',
          );
        }
      });
    }
  }

  /// Precache images adjacent to the current index for smooth carousel navigation
  /// Uses same URL normalization and cache parameters as carousel
  void _precacheAdjacentImages(int currentIndex) {
    final photos = post.value?.photoPaths;
    if (photos == null || photos.isEmpty) return;

    final context = Get.context;
    if (context == null) return;

    // Precache next image with matching dimensions and normalized URL
    if (currentIndex + 1 < photos.length) {
      final rawPath = photos[currentIndex + 1];
      final normalizedPath = rawPath.replaceAll('\\', '/');

      final cleanBaseUrl = ApiKey.ip.endsWith('/')
          ? ApiKey.ip.substring(0, ApiKey.ip.length - 1)
          : ApiKey.ip;
      final cleanPath = normalizedPath.startsWith('/')
          ? normalizedPath
          : '/$normalizedPath';
      final nextImageUrl = '$cleanBaseUrl$cleanPath';

      precacheImage(
        CachedNetworkImageProvider(
          nextImageUrl,
          maxWidth: 4800,
          maxHeight: 3600,
        ),
        context,
      ).catchError((e) {
        if (kDebugMode) {
          debugPrint('[PostDetailsController] ❌ Precache next failed: $e');
        }
      });
    }

    // Precache previous image with matching dimensions and normalized URL
    if (currentIndex - 1 >= 0) {
      final rawPath = photos[currentIndex - 1];
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
        if (kDebugMode) {
          debugPrint('[PostDetailsController] ❌ Precache prev failed: $e');
        }
      });
    }
  }

  final RxBool isPlaying = false.obs;
  final String apiKeyIp = ApiKey.ip;
  // VideoPlayerController? _videoPlayerController;
  // List<String> _orderedUrls = [];
  // int _currentVideoIndex = 0;

  Future<void> fetchProductDetails(String uuid) async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiKey.getPostDetailsKey}$uuid?model=true&brand=true&photo=true',
        ),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          final videoSection = data['video'];
          debugPrint(
            '[PostDetailsController] video section raw: $videoSection',
          );
        }
        post.value = Post.fromJson(data);
        if (kDebugMode)
          debugPrint(
            '[PostDetailsController] parsed post video: ${post.value?.video}',
          );

        // Precache first 3 images for smooth initial carousel experience
        _precacheInitialImages();
      }
      if (response.statusCode == 406) {
        // await refreshAccesToken(uuid); // ✅ Pass the uuid here
      }
    } catch (e) {
      return;
    } finally {
      isLoading.value = false;
    }
  }

  // Future<void> refreshAccesToken(String uuid) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse(ApiKey.refreshTokenKey),
  //       headers: {
  //         "Content-Type": "application/json",
  //         'Authorization': 'Bearer ${box.read('REFRESH_TOKEN')}'
  //       },
  //     );
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final newAccessToken = data['accessToken'];
  //       box.write('ACCESS_TOKEN', newAccessToken);

  //       await fetchProductDetails(uuid); // ✅ Safe retry
  //     }
  //   } catch (e) {
  //     print('Token refresh failed: $e');
  //   }
  // }
  Future<void> refreshAccesToken(String uuid) async {
    try {
      final refreshToken = box.read('REFRESH_TOKEN');

      final response = await http.get(
        Uri.parse(ApiKey.refreshTokenKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        if (newAccessToken != null) {
          box.write('ACCESS_TOKEN', newAccessToken);
          await fetchProductDetails(uuid);
        } else {}
      } else {}
    } catch (e) {
      return;
    }
  }

  void makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {}
  }

  void showVideoPage(Video video) {
    if (video.url != null && video.url!.isNotEmpty) {
      List<String> orderedUrls = List.from(
        video.url!,
      ).map((url) => '$apiKeyIp$url').toList();
      if (video.partNumber != null) {
        orderedUrls.sort((a, b) {
          final partA =
              int.tryParse(a.split('_part').last.replaceAll('.mp4', '')) ?? 0;
          final partB =
              int.tryParse(b.split('_part').last.replaceAll('.mp4', '')) ?? 0;
          return partB.compareTo(partA); // Обратный порядок
        });
      } else {
        orderedUrls = orderedUrls.reversed.toList();
      }
      Get.to(
        () => VideoPlayerPage(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => FullVideoPlayerController());
        }),
        arguments: orderedUrls,
      );
    } else {
      ('Ошибка', 'Нет URL-адресов для воспроизведения видео');
    }
  }
}
