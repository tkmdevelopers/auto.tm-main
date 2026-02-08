import 'dart:io';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:auto_tm/services/blog_service.dart';

class CreateBlogController extends GetxController {
  final BlogService _blogService; // Injected BlogService

  CreateBlogController(this._blogService);

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageLink = Rx<String?>(null);
  final isUploading = Rx<bool>(false);
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      isUploading.value = true; // Start uploading indicator
      try {
        final url = await _blogService.uploadImage(File(pickedFile.path));
        if (url != null) {
          imageLink.value = ApiKey.ip + url; // Assuming ApiKey.ip is the base for displaying
          Get.snackbar('Uploaded', 'Image uploaded successfully!');
        } else {
          Get.snackbar('Upload Failed', 'Failed to upload image.');
          imageLink.value = null;
        }
      } catch (error) {
        Get.snackbar('Error', 'Error uploading image: $error');
        imageLink.value = null;
      } finally {
        isUploading.value = false; // End uploading indicator
      }
    } else {
      Get.snackbar('Cancelled', 'No image selected.');
    }
  }

  Future<void> postBlog() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in title and description.');
      return;
    }

    String description;
    if (imageLink.value != null) {
      description = '${imageLink.value}${descriptionController.text}';
    } else {
      description = descriptionController.text;
    }

    try {
      await _blogService.postBlog(description); // Delegate to service
      Get.snackbar('Success', 'Blog posted!');
      titleController.clear();
      descriptionController.clear();
      imageLink.value = null;
      Get.back();
    } catch (error) {
      // BlogService already handles snackbar for errors, or ApiClient interceptor does.
      Get.log('Error from CreateBlogController: $error');
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
