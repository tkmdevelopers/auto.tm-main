import 'dart:convert';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class CommentsController extends GetxController {
  final TextEditingController commentTextController = TextEditingController();
  var comments = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isSending = false.obs; // prevents duplicate rapid sends

  var replyToComment =
      Rxn<Map<String, dynamic>>(); // Stores selected comment for reply
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

  bool isThreadExpanded(String parentUuid) =>
      threadExpanded[parentUuid] ?? false;

  String? _lastFetchedPostId;

  // Fetch comments for a specific post (skips if same postId already fetched)
  Future<void> fetchComments(String postId) async {
    if (postId.isEmpty) return;
    if (postId == _lastFetchedPostId) return;
    _lastFetchedPostId = postId;
    isLoading.value = true;
    try {
      final response = await ApiClient.to.dio.get(
        'comments',
        queryParameters: {'postId': postId},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<dynamic> list = data is List
            ? data as List
            : (data is Map && data['data'] != null)
                ? (data['data'] as List)
                : (data is Map && data['results'] != null)
                    ? (data['results'] as List)
                    : [];
        final rawList = list
            .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))
            .toList();
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
            replyMap[parentId.toString()] =
                (replyMap[parentId.toString()] ?? 0) + 1;
          }
        }
        for (final parentId in replyMap.keys) {
          threadExpanded.putIfAbsent(
            parentId,
            () => false,
          ); // collapsed by default
        }
        // Debug: log if duplicates were removed
        final removed = rawList.length - unique.length;
        if (removed > 0) {
          // ignore: avoid_print
          print('[COMMENTS] Removed $removed duplicate comment(s)');
        }
        Future.delayed(Duration.zero, () {
          // Schedule for next frame
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
    if (message.isEmpty || isSending.value) return;
    if (!(await TokenStore.to.hasTokens)) {
      Get.snackbar('', 'Log in to comment'.tr);
      Get.toNamed('/register');
      return;
    }
    isSending.value = true;

    final commentData = {"postId": postId, "message": message};

    // If replying, attach `replyTo` UUID
    if (replyToComment.value != null) {
      commentData["replyTo"] = replyToComment.value!["uuid"];
    }

    try {
      final response = await ApiClient.to.dio.post(
        'comments',
        data: commentData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newComment = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data is String ? response.data as String : '{}') as Map<String, dynamic>;
        final id = newComment['uuid']?.toString();
        final exists =
            id != null && comments.any((c) => c['uuid']?.toString() == id);
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
