import 'package:auto_tm/screens/blog_screen/controller/blog_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlogDetailScreen extends StatelessWidget {
  final String blogId;
  BlogDetailScreen({super.key, required this.blogId});

  final BlogController controller = Get.put(BlogController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        title: Text("Blog Details".tr),
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<String>(
        future: controller.fetchBlogDetails(blogId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(child: Text("Failed to load blog details".tr));
          }

          return Padding(
            padding: EdgeInsets.all(10),
            child: _buildContentWithImages(
                snapshot.data!, theme.colorScheme.primary),
          );
        },
      ),
    );
  }

  Widget _buildContentWithImages(String content, Color color) {
    List<Widget> contentWidgets = [];
    RegExp regex = RegExp(r'(https?:\/\/\S+\.(jpg|jpeg|png|webp))');
    Iterable<Match> matches = regex.allMatches(content);

    int lastIndex = 0;
    for (var match in matches) {
      if (match.start > lastIndex) {
        contentWidgets.add(Text(content.substring(lastIndex, match.start)));
      }
      contentWidgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                match.group(0)!,
                width: double.infinity,
                fit: BoxFit.cover,
                height: 230,
              )),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      contentWidgets.add(Text(
        content.substring(lastIndex),
        style: TextStyle(
          fontSize: 16,
          color: color,
        ),
      ));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentWidgets,
        ),
      ),
    );
  }
}
