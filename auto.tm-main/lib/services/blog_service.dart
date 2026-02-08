import 'dart:io';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';

class BlogService extends GetxService {
  final ApiClient _apiClient;

  BlogService(this._apiClient); // Constructor injection

  Future<String?> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split(RegExp(r'[/\]')).last),
      });
      final response = await _apiClient.dio.post('photo/vlog', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map;
        final uuid = data['uuid'];
        if (uuid is Map) {
          final path = uuid['path'];
          if (path is Map && path['medium'] != null) return path['medium'] as String;
        }
      }
    } catch (e) {
      Get.log('Error uploading image: $e'); // Use Get.log for better logging
      return null;
    }
    return null;
  }

  Future<void> postBlog(String content) async {
    try {
      await _apiClient.dio.post(
        'vlog',
        data: {'description': content},
      );
    } on DioException catch (e) { // Catch DioException
      Get.log('Error posting blog: ${e.message ?? e.toString()}');
      Get.snackbar('Error', 'Failed to post blog: ${e.message ?? e.toString()}'); // Provide user feedback
    } catch (e) {
      Get.log('Error posting blog: $e');
      Get.snackbar('Error', 'Failed to post blog: $e');
    }
  }
}
