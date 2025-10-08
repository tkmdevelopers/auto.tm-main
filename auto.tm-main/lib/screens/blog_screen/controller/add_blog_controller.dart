// blog_editor_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class BlogEditorController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final box = GetStorage();
  final picker = ImagePicker();
  final images = <String>[].obs;

  Future<void> insertImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final url = await uploadImage(File(picked.path));
      if (url != null) {
        final cursor = textController.selection.baseOffset;
        final newText = textController.text.replaceRange(cursor, cursor, '\n$url\n');
        textController.text = newText;
        textController.selection = TextSelection.collapsed(offset: cursor + url.length + 2);
        images.add(url);
      }
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiKey.postBlogPhotoKey),
      );
      request.headers['Authorization'] = 'Bearer ${box.read('ACCESS_TOKEN')}';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body);
        return data['uuid']['path']['medium'];
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
      final response = await http.post(
        Uri.parse(ApiKey.postBlogsKey),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}'},
        body: jsonEncode({"description": content}),
      );
      if (response.statusCode == 200) {
        Get.back();
        ('Success', 'Blog posted');
      } else {
      }
    } catch (e) {
      return;
    }
  }
}
