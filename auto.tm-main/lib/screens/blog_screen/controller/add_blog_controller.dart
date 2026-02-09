// blog_editor_controller.dart
import 'dart:io';
import 'package:auto_tm/services/blog_service.dart'; // Added BlogService import
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class BlogEditorController extends GetxController {
  final BlogService _blogService; // Injected BlogService

  BlogEditorController(this._blogService);
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
    return await _blogService.uploadImage(file);
  }

  Future<void> postBlog() async {
    final content = textController.text.trim();
    if (content.isEmpty) return;

    await _blogService.postBlog(content);
    Get.back();
    Get.snackbar('Success', 'Blog posted');
  }
}
