import 'dart:io';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

// Controller
class CreateBlogController extends GetxController {
  final titleController = TextEditingController();
  final descriptionController =
      TextEditingController(); // Use обычный TextEditingController
  final imageLink = Rx<String?>(null);
  final isUploading = Rx<bool>(false);
  final picker = ImagePicker(); // Keep ImagePicker instance

  // Pick an image from device
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    ); // Use the instance

    if (pickedFile != null) {
      await uploadImage(File(pickedFile.path));
    } else {
      ('Cancelled', 'No image selected.');
    }
  }

  // Upload image to backend
  Future<void> uploadImage(File imageFile) async {
    isUploading.value = true;
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      });
      final response = await ApiClient.to.dio.post('photo/vlog', data: formData);

      if (response.statusCode == 200 && response.data != null) {
        final responseJson = response.data as Map;
        final uuid = responseJson['uuid'];
        if (uuid is Map && uuid['path'] is Map) {
          final medium = (uuid['path'] as Map)['medium'];
          if (medium != null) {
            imageLink.value = ApiKey.ip + medium.toString();
            Get.snackbar('Uploaded', 'Image uploaded successfully!');
            return;
          }
        }
        imageLink.value = null;
      } else {
        Get.snackbar(
          'Upload Failed',
          'Failed to upload image. Status code: ${response.statusCode}',
        );
        imageLink.value = null;
      }
    } catch (error) {
      Get.snackbar('Error', 'Error uploading image: $error');
      imageLink.value = null;
    } finally {
      isUploading.value = false;
    }
  }

  // Post the blog with image link
  Future<void> postBlog() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      // Изменено на text.isEmpty
      ('Error', 'Please fill in title and description.');
      return;
    }

    // Include the image link as markdown if available
    String description;
    if (imageLink.value != null) {
      description =
          '${imageLink.value}${descriptionController.text}'; // Изменено на  descriptionController.text
    } else {
      description =
          descriptionController.text; // Изменено на  descriptionController.text
    }

    try {
      final response = await ApiClient.to.dio.post(
        'vlog',
        data: {'title': titleController.text, 'description': description},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Blog posted!');
        titleController.clear();
        descriptionController.clear();
        imageLink.value = null;
        Get.back();
      } else {
        Get.snackbar(
          'Error',
          'Failed to post blog. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      Get.snackbar('Error', 'Error posting blog: $error');
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}

// Screen
class CreateBlogScreen extends StatelessWidget {
  final CreateBlogController controller = Get.put(CreateBlogController());
  final _formKey = GlobalKey<FormState>();

  CreateBlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Create new blog".tr,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          //wrap form
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Title Input
                TextFormField(
                  controller: controller.titleController,
                  style: TextStyle(color: theme.colorScheme.primary),
                  decoration: InputDecoration(
                    labelText: 'Title'.tr,
                    labelStyle: TextStyle(color: AppColors.textTertiaryColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                // Description Input (Plain TextField)
                Text(
                  'Description'.tr,
                  style: TextStyle(
                    color: AppColors.textTertiaryColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: controller.descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 10, // Or any other number
                  decoration: InputDecoration(
                    hintText: 'Write description here...'.tr,
                    hintStyle: TextStyle(color: AppColors.textTertiaryColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                // Image Upload Button
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.pickImage,
                      icon: Icon(Icons.photo, color: AppColors.whiteColor),
                      label: Text(
                        'Photo'.tr,
                        style: TextStyle(color: AppColors.whiteColor),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textTertiaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isUploading.value) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 10.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(height: 20.0),
                // Display Image
                Obx(() {
                  if (controller.imageLink.value != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uploaded Image:'.tr,
                          style: TextStyle(
                            color: AppColors.textTertiaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          controller.imageLink.value!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 20.0),
                // Post Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      //validate form
                      controller.postBlog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text('Publish'.tr, style: TextStyle(fontSize: 18.0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
