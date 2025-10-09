import 'package:auto_tm/global_widgets/refresh_indicator.dart';
import 'package:auto_tm/screens/blog_screen/controller/blog_controller.dart';
import 'package:auto_tm/screens/blog_screen/widgets/blog_detais_screen.dart';
import 'package:auto_tm/screens/blog_screen/widgets/blog_shimmer.dart';
import 'package:auto_tm/services/token_service/token_service.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class BlogScreen extends StatelessWidget {
  final BlogController controller = Get.put(BlogController());
  final tokenService = Get.put(TokenService());

  BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
  // Initial fetch handled in BlogController.onInit()
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation:4,
        title: Text(
          'blog_list_title'.tr, // standardized blog list title key
          style: AppStyles.f18w6.copyWith(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        actions: [
          // Posting temporarily disabled
          // Padding(
          //   padding: const EdgeInsets.only(right: 10.0),
          //   child: IconButton(
          //       onPressed: () {
          //         final token = tokenService.getToken();
          //         if (token == null || token.isEmpty) {
          //           Future.delayed(
          //               Duration.zero, () => Get.toNamed('/register'));
          //         } else {
          //           Future.delayed(
          //               Duration.zero, () => Get.to(() => CreateBlogScreen()));
          //         }
          //       },
          //       icon: Icon(
          //         Icons.add,
          //         size: 21,
          //         color: theme.colorScheme.onSurface,
          //       )),
          // )
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SRefreshIndicator(
        onRefresh: () async => controller.fetchBlogs(),
        child: Obx(() {
          if (controller.isLoading.value) {
            // return Center(child: CircularProgressIndicator());
            return ListView.builder(
              // physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 5,
              itemBuilder: (context, index) {
                return const BlogItemShimmer();
              },
            );
          }
          if (controller.blogs.isEmpty) {
            return Center(child: Text('There are no blogs'.tr)); // blog_empty
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            separatorBuilder: (_, __) {
              return SizedBox(
                height: 16,
              );
            },
            itemCount: controller.blogs.length,
            itemBuilder: (context, index) {
              var blog = controller.blogs[index];
              return GestureDetector(
                onTap: () {
                  Get.to(() => BlogDetailScreen(blogId: blog.uuid));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: theme.shadowColor, blurRadius: 5)
                    ],
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  padding: EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.year,
                            width: 12,
                            height: 12,
                            colorFilter: ColorFilter.mode(theme.colorScheme.onSurface.withOpacity(0.7), BlendMode.srcIn),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            controller.formatDate(blog.date),
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF969696)),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        blog.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      // Wrap(
                      // children: [Text(blog.description, style: TextStyle(fontSize: 12, color: Color(0xFFA4A4A4),),maxLines: 3, overflow: TextOverflow.ellipsis,)],
                      // ),
            _buildContentWithImages(
              blog.description, theme.colorScheme.onSurface),
                    ],
                  ),
                ),
              );
            },
          );
        }),
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
                height: 130,
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      ),
    );
  }
}
