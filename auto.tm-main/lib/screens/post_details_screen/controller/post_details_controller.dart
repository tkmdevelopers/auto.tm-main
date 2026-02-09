import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailsController extends GetxController {
  PostDetailsController({String? uuid}) : _uuid = uuid;

  final String? _uuid;
  var post = Rxn<Post>();
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;
  var currentPage = 0.obs;

  String? get uuid => _uuid;

  void retry() {
    if (_uuid != null && _uuid!.isNotEmpty) {
      isError.value = false;
      errorMessage.value = '';
      fetchProductDetails(_uuid!);
    }
  }

  void setCurrentPage(int index) {
    currentPage.value = index;
  }

  @override
  void onReady() {
    super.onReady();
    if (_uuid != null && _uuid!.isNotEmpty) {
      fetchProductDetails(_uuid!);
    }
  }

  Future<void> fetchProductDetails(String uuid) async {
    isLoading.value = true;
    isError.value = false;
    errorMessage.value = '';
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
        post.value = PostLegacyExtension.fromJson(data);
        if (kDebugMode)
          debugPrint(
            '[PostDetailsController] parsed post video: ${post.value?.video}',
          );
      } else {
        isError.value = true;
        errorMessage.value = response.statusCode == 404
            ? 'Post not found'.tr
            : 'Something went wrong'.tr;
        post.value = null;
      }
    } catch (e) {
      isError.value = true;
      errorMessage.value = 'Unable to load post'.tr;
      post.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {}
  }

}
