import 'dart:convert';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CommentsController extends GetxController {
  final TextEditingController commentTextController = TextEditingController();
  final box = GetStorage();
  var comments = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var userId = "".obs;
  var isSending = false.obs; // prevents duplicate rapid sends

  var replyToComment = Rxn<Map<String, dynamic>>(); // Stores selected comment for reply
  // Track expansion state per parent comment uuid
  final threadExpanded = <String, bool>{}.obs;

  // Cached grouped structure: parent uuid -> list of replies
  Map<String, List<Map<String, dynamic>>> get groupedReplies {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final c in comments) {
      final replyTo = c['replyTo'];
      if (replyTo != null) {
        map.putIfAbsent(replyTo.toString(), () => []).add(c);
      }
    }
    return map;
  }

  void toggleThread(String parentUuid) {
    threadExpanded[parentUuid] = !(threadExpanded[parentUuid] ?? false);
    // trigger reactive update
    threadExpanded.refresh();
  }

  bool isThreadExpanded(String parentUuid) => threadExpanded[parentUuid] ?? false;


  // Fetch comments for a specific post
  Future<void> fetchComments(String postId) async {
    // isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse("${ApiKey.getCommentsKey}?postId=$postId"),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
        },
      );
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        final rawList = List<Map<String, dynamic>>.from(decodedData);
        // Deduplicate by uuid
        final seen = <String>{};
        final unique = <Map<String, dynamic>>[];
        for (final c in rawList) {
          final id = c['uuid']?.toString();
            if (id != null) {
              if (seen.add(id)) {
                unique.add(c);
              }
            } else {
              unique.add(c); // keep those without uuid just in case
            }
        }
        comments.value = unique;
        // Initialize expansion state for any new parents (default collapsed if they have >0 replies)
        final replyMap = <String, int>{};
        for (final c in unique) {
          final parentId = c['replyTo'];
            if (parentId != null) {
              replyMap[parentId.toString()] = (replyMap[parentId.toString()] ?? 0) + 1;
            }
        }
        for (final parentId in replyMap.keys) {
          threadExpanded.putIfAbsent(parentId, () => false); // collapsed by default
        }
        // Debug: log if duplicates were removed
        final removed = rawList.length - unique.length;
        if (removed > 0) {
          // ignore: avoid_print
          print('[COMMENTS] Removed $removed duplicate comment(s)');
        }
        Future.delayed(Duration.zero, () { // Schedule for next frame
        isLoading.value = false;
      });
      } else {
        Future.delayed(Duration.zero, () {
          isLoading.value = false;
        });
      }
    } catch (e) {
      Future.delayed(Duration.zero, () {
        isLoading.value = false;
      });
    }
  }

  // Send a comment or reply
  Future<void> sendComment(String postId, String message) async {
    // if (userId.value.isEmpty || userId.value == '') {
    //   Get.toNamed('/profile'); // Navigate to Profile Screen if user is not logged in
    //   return;
    // }
  if (message.isEmpty || isSending.value) return;
  isSending.value = true;

    final commentData = {
      "postId": postId,
      "message": message,
    };

    // If replying, attach `replyTo` UUID
    if (replyToComment.value != null) {
      commentData["replyTo"] = replyToComment.value!["uuid"];
    }

    try {
      final response = await http.post(
        Uri.parse(ApiKey.postCommentsKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',
        },
        body: jsonEncode(commentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newComment = jsonDecode(response.body);
        final id = newComment['uuid']?.toString();
        final exists = id != null && comments.any((c) => c['uuid']?.toString() == id);
        if (!exists) {
          comments.add(newComment); // Add new unique comment to list
        }
        replyToComment.value = null; // Clear reply after sending
      }
    } catch (e) {
      // ignore error silently
    } finally {
      isSending.value = false;
    }
  }

  // Token refresh is now handled by the Dio ApiClient interceptor.
  // The duplicated refreshAccessToken() method has been removed.

  // Set a comment as the one being replied to
  void setReplyTo(Map<String, dynamic> comment) {
    replyToComment.value = comment;
  }

  // Clear reply
  void clearReply() {
    replyToComment.value = null;
  }
}
