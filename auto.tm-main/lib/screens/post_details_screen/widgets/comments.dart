import 'package:auto_tm/screens/post_details_screen/controller/comments_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final CommentsController controller = Get.put(CommentsController());

  String uuid = Get.arguments;

  @override
  Widget build(BuildContext context) {
    // controller.fetchComments(uuid);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(elevation:4,
        automaticallyImplyLeading: true,
        title: Text(
          'Comments'.tr,
          style: TextStyle(
            color: theme.colorScheme.onSurface, // updated to onSurface per request
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Obx(() => controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: controller.comments.length,
                    itemBuilder: (context, index) {
                      final comment = controller.comments[index];
                      final String formattedDate =
                          DateFormat("MM.dd.yyyy | hh:mm")
                              .format(DateTime.parse(comment["createdAt"]));
                      // bool isMine = comment['userId'] == controller.box.read('USER_ID');
                      bool isReply = comment.containsKey("replyTo") &&
                          comment["replyTo"] != null;

                      return Column(
                        // crossAxisAlignment:
                        //     isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onLongPress: () => controller
                                .setReplyTo(comment), // Select for reply
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 16),
                              width: double.maxFinite,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                // color: isMine ? AppColors.primaryColor : theme.colorScheme.primaryContainer,
                                color: theme.colorScheme.secondaryContainer,
                                border: Border.all(
                                  color: AppColors.textTertiaryColor,
                                  width: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(12
                                    // topLeft: Radius.circular(12),
                                    // topRight: Radius.circular(12),
                                    // bottomLeft: isMine ? Radius.circular(12) : Radius.zero,
                                    // bottomRight: isMine ? Radius.zero : Radius.circular(12),
                                    ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isReply) // Show replied-to message
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        "Replying to: ${comment["replyTo"]}",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        radius: 16.0,
                                        child: Icon(Icons.person,
                                            color: Colors.white,
                                            size:
                                                20.0), // Placeholder avatar
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Text(
                                          "@${comment['sender']}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                AppColors.textTertiaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                          color:
                                              AppColors.textTertiaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comment['message'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // SizedBox(height: 0,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                          onPressed: () {},
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.backspace_outlined,
                                                color: AppColors.primaryColor,
                                                size: 12,
                                              ),
                                              SizedBox(
                                                width: 8,
                                              ),
                                              Text(
                                                'Reply'.tr,
                                                style: TextStyle(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              )
                                            ],
                                          ))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )),
          ),

          // Show Reply Banner if Replying
          Obx(() => controller.replyToComment.value != null
              ? Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.grey[300],
                  child: Row(
                    children: [
                      Text(
                          "Replying to: ${controller.replyToComment.value!['message']}"),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => controller.clearReply(),
                      ),
                    ],
                  ),
                )
              : SizedBox.shrink()),

          // Comment Input
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.commentTextController,
                    decoration: InputDecoration(hintText: "Write a comment..."),
                  ),
                ),
                InkWell(
                  onTap: () {
                    controller.sendComment(
                        uuid, controller.commentTextController.text);
                    controller.commentTextController.clear();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_upward_outlined,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
                // IconButton(
                //   icon: Icon(Icons.arrow_upward_rounded),
                //   onPressed: () {
                //     controller.sendComment(uuid, controller.commentTextController.text);
                //     controller.commentTextController.clear();
                //   },
                // )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// import 'package:auto_tm/screens/post_details_screen/controller/comments_controller.dart';
// import 'package:auto_tm/ui_components/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class CommentsPage extends StatelessWidget {
//   CommentsPage({super.key});
//   final CommentsController controller = Get.put(CommentsController());
//   String uuid = Get.arguments;

//   @override
//   Widget build(BuildContext context) {
//     controller.fetchComments(uuid);
//     return Scaffold(
//       appBar: AppBar(elevation:4,
//         automaticallyImplyLeading: true,
//         backgroundColor: AppColors.whiteColor,
//         surfaceTintColor: AppColors.textGreyColor,
//       ),
//       backgroundColor: AppColors.bgColor,
//       body: Column(
//         children: [
//           Expanded(
//             child: Obx(() => controller.isLoading.value
//                 ? Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//                     itemCount: controller.comments.length,
//                     itemBuilder: (context, index) {
//                       final comment = controller.comments[index];
//                       return CommentItem(comment: comment, controller: controller);
//                     },
//                   )),
//           ),

//           // Show Reply Banner if Replying
//           Obx(() => controller.replyToComment.value != null
//               ? Container(
//                   padding: EdgeInsets.all(8),
//                   color: Colors.grey[300],
//                   child: Row(
//                     children: [
//                       Text("Replying to: ${controller.replyToComment.value!['message']}"),
//                       Spacer(),
//                       IconButton(
//                         icon: Icon(Icons.close),
//                         onPressed: () => controller.clearReply(),
//                       ),
//                     ],
//                   ),
//                 )
//               : SizedBox.shrink()),

//           // Comment Input
//           Padding(
//             padding: EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: controller.commentTextController,
//                     decoration: InputDecoration(hintText: "Write a comment..."),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: () {
//                     controller.sendComment(uuid, controller.commentTextController.text);
//                     controller.commentTextController.clear();
//                   },
//                 )
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// class CommentItem extends StatefulWidget {
//   final Map<String, dynamic> comment;
//   final CommentsController controller;
//   const CommentItem({Key? key, required this.comment, required this.controller}) : super(key: key);

//   @override
//   _CommentItemState createState() => _CommentItemState();
// }

// class _CommentItemState extends State<CommentItem> {
//   bool showReplies = false;

//   @override
//   Widget build(BuildContext context) {
//     final bool isReply = widget.comment.containsKey("replyTo") && widget.comment["replyTo"] != null;
//     final String formattedDate = DateFormat("MM/dd/yyyy").format(DateTime.parse(widget.comment["createdAt"]));

//     return Padding(
//       padding: EdgeInsets.only(left: isReply ? 30.0 : 10.0, right: 10, bottom: 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Comment Box
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.2),
//                   spreadRadius: 1,
//                   blurRadius: 3,
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Profile and Date
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: Colors.yellow,
//                       child: Icon(Icons.android, color: Colors.blue),
//                     ),
//                     SizedBox(width: 10),
//                     Text(
//                       widget.comment["sender"] ?? "User",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(width: 8),
//                     Text(
//                       formattedDate,
//                       style: TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 5),

//                 // Comment Text
//                 Text(
//                   widget.comment["message"],
//                   style: TextStyle(fontSize: 14),
//                 ),

//                 // Reply Button
//                 TextButton(
//                   onPressed: () => widget.controller.setReplyTo(widget.comment),
//                   child: Text("Reply", style: TextStyle(color: Colors.blue)),
//                 ),

//                 // Toggle Replies
//                 if (widget.controller.comments.any((c) => c["replyTo"] == widget.comment["uuid"]))
//                   GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         showReplies = !showReplies;
//                       });
//                     },
//                     child: Row(
//                       children: [
//                         Icon(showReplies ? Icons.remove : Icons.add, size: 14, color: Colors.grey),
//                         SizedBox(width: 5),
//                         Text(
//                           showReplies ? "Hide replies" : "Show replies",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Show Replies
//           if (showReplies)
//             Column(
//               children: widget.controller.comments
//                   .where((c) => c["replyTo"] == widget.comment["uuid"])
//                   .map((reply) => CommentItem(comment: reply, controller: widget.controller))
//                   .toList(),
//             ),
//         ],
//       ),
//     );
//   }
// }
