import 'dart:convert';

import 'package:auto_tm/screens/post_details_screen/controller/video_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/video_player.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailsController extends GetxController {
  var post = Rxn<Post>();
  var isLoading = true.obs;
  var currentPage = 0.obs;

  void setCurrentPage(int index) {
    currentPage.value = index;
  }

  final RxBool isPlaying = false.obs;
  final String apiKeyIp = ApiKey.ip;
  // VideoPlayerController? _videoPlayerController;
  // List<String> _orderedUrls = [];
  // int _currentVideoIndex = 0;

  Future<void> fetchProductDetails(String uuid) async {
    isLoading.value = true;
    try {
      final response = await ApiClient.to.dio.get(
        'posts/$uuid',
        queryParameters: {'model': true, 'brand': true, 'photo': true},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : json.decode(response.data is String ? response.data as String : '{}') as Map<String, dynamic>;
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
