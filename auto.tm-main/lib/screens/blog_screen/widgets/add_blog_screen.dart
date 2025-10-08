import 'dart:io';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path; // Import path

// Controller
class CreateBlogController extends GetxController {
  final box = GetStorage();
  final titleController = TextEditingController();
  final descriptionController =
      TextEditingController(); // Use обычный TextEditingController
  final imageLink = Rx<String?>(null);
  final isUploading = Rx<bool>(false);
  final picker = ImagePicker(); // Keep ImagePicker instance

  // Pick an image from device
  Future<void> pickImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery); // Use the instance

    if (pickedFile != null) {
      await uploadImage(File(pickedFile.path));
    } else {
      ('Cancelled', 'No image selected.');
    }
  }

  // Upload image to backend (mock implementation)
  Future<void> uploadImage(File imageFile) async {
    isUploading.value = true;
    try {
      // 1. Prepare the image for upload
      var request = http.MultipartRequest(
          'POST', Uri.parse(ApiKey.postBlogPhotoKey)); // Replace with your upload URL
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      // 2. Create a MultipartFile
      var multipartFile = http.MultipartFile(
        'file', // This should match your server's expected field name
        stream,
        length,
        filename: path.basename(imageFile.path), // Use path package
        contentType: MediaType('image', 'jpeg'),
      );

      request.headers['Authorization'] = 'Bearer ${box.read('ACCESS_TOKEN')}';

      // 3. Add the file to the request
      request.files.add(multipartFile);

      // 4. Send the request
      var response = await request.send();

      // 5. Get the response
      var responseBody = await response.stream.bytesToString();

      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      if (response.statusCode == 200) {
        var responseJson = jsonDecode(responseBody);
        // Ensure your backend returns a JSON object with the imageUrl
        imageLink.value = ApiKey.ip + responseJson['uuid']['path']['medium'];
        ('Uploaded', 'Image uploaded successfully!');
      } else {
        ('Upload Failed',
            'Failed to upload image. Status code: ${response.statusCode}, Response: $responseBody');
        imageLink.value = null; //important
      }
    } catch (error) {
      ('Error', 'Error uploading image: $error');
      imageLink.value = null; //important
    } finally {
      isUploading.value = false;
    }
  }

  // Post the blog with image link
  Future<void> postBlog() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty) { // Изменено на text.isEmpty
      ('Error', 'Please fill in title and description.');
      return;
    }

    // Include the image link as markdown if available
    String description;
    if (imageLink.value != null) {
      description =
          '${imageLink.value}${descriptionController.text}'; // Изменено на  descriptionController.text
    } else {
      description = descriptionController.text; // Изменено на  descriptionController.text
    }

    // Simulate posting the blog.  Replace with your actual API call.
    try {
      var response = await http.post(
        Uri.parse(ApiKey.postBlogsKey), // Replace
        headers: {
          // "Accept": "application/json",
          // "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}'
        },
        body: {
          'title': titleController.text,
          'description': description,
        },
      );
      await Future.delayed(const Duration(seconds: 1));

      if (response.statusCode == 200 || response.statusCode == 201) {
        ('Success', 'Blog posted!');
        // Clear the form
        titleController.clear();
        descriptionController.clear();
        imageLink.value = null;
        Get.back(); // Go back to previous screen
      } else {
        ('Error',
            'Failed to post blog. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (error) {
      ('Error', 'Error posting blog: $error');
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
      appBar: AppBar(elevation:4,
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
        child: Form( //wrap form
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
                  style: TextStyle(color: AppColors.textTertiaryColor, fontSize: 16),
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
                          style: TextStyle(color: AppColors.textTertiaryColor, fontSize: 16),
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
                    if(_formKey.currentState!.validate()){ //validate form
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
                  child: Text(
                    'Publish'.tr,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

