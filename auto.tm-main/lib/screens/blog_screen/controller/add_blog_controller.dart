// blog_editor_controller.dart
import 'dart:io';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class BlogEditorController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final picker = ImagePicker();
  final images = <String>[].obs;

  Future<void> insertImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final url = await uploadImage(File(picked.path));
      if (url != null) {
        final cursor = textController.selection.baseOffset;
        final newText = textController.text.replaceRange(
          cursor,
          cursor,
          '\n$url\n',
        );
        textController.text = newText;
        textController.selection = TextSelection.collapsed(
          offset: cursor + url.length + 2,
        );
        images.add(url);
      }
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split(RegExp(r'[/\\]')).last),
      });
      final response = await ApiClient.to.dio.post('photo/vlog', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map;
        final uuid = data['uuid'];
        if (uuid is Map) {
          final path = uuid['path'];
          if (path is Map && path['medium'] != null) return path['medium'] as String;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> postBlog() async {
    final content = textController.text.trim();
    if (content.isEmpty) return;

    try {
      final response = await ApiClient.to.dio.post(
        'vlog',
        data: {'description': content},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar('Success', 'Blog posted');
      }
    } catch (e) {
      // Handled by ApiClient interceptor
    }
  }
}
