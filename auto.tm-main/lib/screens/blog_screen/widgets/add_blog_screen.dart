import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/create_blog_controller.dart';
import 'package:auto_tm/services/blog_service.dart';

class CreateBlogScreen extends StatelessWidget {
  final CreateBlogController controller = Get.put(CreateBlogController(Get.find<BlogService>()));
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
