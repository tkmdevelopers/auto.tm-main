import 'package:auto_tm/screens/post_details_screen/controller/comments_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CommentCarousel extends StatelessWidget {
  final String postId;

  CommentCarousel({super.key, required this.postId});
  final controller = Get.put(CommentsController());

  @override
  Widget build(BuildContext context) {
    controller.fetchComments(postId); // Fetch comments when the widget is built
final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      } else if (controller.comments.isEmpty) {
        return Center(child: Text('No comments yet.'.tr));
      } else {
        return CarouselSlider.builder(
          itemCount: controller.comments.length,
          itemBuilder: (BuildContext context, int index, int realIndex) {
            final finalComment = controller.comments[index];
            final String formattedDate = DateFormat("MM/dd/yyyy")
                .format(DateTime.parse(finalComment["createdAt"]));
            final username = finalComment['sender'] ?? '@user';
            final message = finalComment['message'] ?? '';
            // final authorName = finalComment['authorName'] ?? 'Anonymous'; // Assuming 'authorName' exists
            // final bool isMine = finalComment['userId'] == controller.userId.value; // You can use this for styling

            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer, // Match the background color
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textTertiaryColor,
                width: 0.5,)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 16.0,
                        child: Icon(Icons.person, color: Colors.white, size: 20.0), // Placeholder avatar
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(child: Text('@$username', style: TextStyle(color: AppColors.textTertiaryColor), overflow: TextOverflow.ellipsis,)),
                      // const Spacer(),
                      Text(formattedDate, style: TextStyle(color: AppColors.textTertiaryColor, fontSize: 12.0)),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(message, style: TextStyle(color: theme.colorScheme.primary,)),
                  const SizedBox(height: 8.0),
                  // Row(
                  //   children: [
                  //     const CircleAvatar(
                  //       backgroundColor: Colors.grey,
                  //       radius: 16.0,
                  //       child: Icon(Icons.person, color: Colors.white, size: 20.0), // Placeholder author avatar
                  //     ),
                  //     const SizedBox(width: 8.0),
                  //     Text(authorName, style: const TextStyle(color: Colors.white)),
                  //   ],
                  // ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            autoPlay: false,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            viewportFraction: 0.9, // Adjust for desired card width
            aspectRatio: 16 / 9, // Adjust as needed
            initialPage: 0,
          ),
        );
      }
    });
  }
}