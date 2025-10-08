import 'dart:convert';

import 'package:auto_tm/screens/post_details_screen/controller/video_controller.dart';
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
            '${ApiKey.getPostDetailsKey}$uuid?model=true&brand=true&photo=true'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        post.value = Post.fromJson(data);
      } if (response.statusCode == 406) {
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
          'Authorization': 'Bearer $refreshToken'
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        if (newAccessToken != null) {
          box.write('ACCESS_TOKEN', newAccessToken);
          await fetchProductDetails(uuid);
        } else {
        }
      } else {
      }
    } catch (e) {
      return;
    }
  }

  void makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
    }
  }

  void showVideoPage(Video video) {
    if (video.url != null && video.url!.isNotEmpty) {
      List<String> orderedUrls = List.from(video.url!).map((url) => '$apiKeyIp$url').toList();
      if (video.partNumber != null) {
        orderedUrls.sort((a, b) {
          final partA = int.tryParse(a.split('_part').last.replaceAll('.mp4', '')) ?? 0;
          final partB = int.tryParse(b.split('_part').last.replaceAll('.mp4', '')) ?? 0;
          return partB.compareTo(partA); // Обратный порядок
        });
      } else {
        orderedUrls = orderedUrls.reversed.toList();
      }
      Get.to(() => VideoPlayerPage(), binding: BindingsBuilder(() {
        Get.lazyPut(() => FullVideoPlayerController());
      }), arguments: orderedUrls);
    } else {
      ('Ошибка', 'Нет URL-адресов для воспроизведения видео');
    }
  }
}
