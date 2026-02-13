import 'package:auto_tm/domain/models/comment.dart';
import 'package:auto_tm/domain/repositories/post_repository.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class CommentsController extends GetxController {
  final PostRepository _postRepository;
  CommentsController({PostRepository? postRepository})
    : _postRepository = postRepository ?? Get.find<PostRepository>();

  final TextEditingController commentTextController = TextEditingController();
  final RxList<Comment> comments = <Comment>[].obs;
  var isLoading = false.obs;
  var isSending = false.obs; // prevents duplicate rapid sends

  var replyToComment = Rxn<Comment>(); // Stores selected comment for reply
  // Track expansion state per parent comment uuid
  final threadExpanded = <String, bool>{}.obs;

  // Cached grouped structure: parent uuid -> list of replies
  Map<String, List<Comment>> get groupedReplies {
    final map = <String, List<Comment>>{};
    for (final c in comments) {
      final replyTo = c.replyTo;
      if (replyTo != null) {
        map.putIfAbsent(replyTo, () => []).add(c);
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
      final result = await _postRepository.getComments(postId);

      // Deduplicate by uuid
      final seen = <String>{};
      final unique = <Comment>[];
      for (final c in result) {
        if (c.uuid.isNotEmpty) {
          if (seen.add(c.uuid)) {
            unique.add(c);
          }
        } else {
          unique.add(c); // keep those without uuid just in case
        }
      }
      comments.assignAll(unique);
      // Initialize expansion state for any new parents (default collapsed if they have >0 replies)
      final replyMap = <String, int>{};
      for (final c in unique) {
        final parentId = c.replyTo;
        if (parentId != null) {
          replyMap[parentId] = (replyMap[parentId] ?? 0) + 1;
        }
      }
      for (final parentId in replyMap.keys) {
        threadExpanded.putIfAbsent(
          parentId,
          () => false,
        ); // collapsed by default
      }
    } catch (e) {
      // ignore
    } finally {
      isLoading.value = false;
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

    try {
      final newComment = await _postRepository.addComment(
        postUuid: postId,
        message: message,
        replyToUuid: replyToComment.value?.uuid,
      );

      if (newComment != null) {
        final exists = comments.any((c) => c.uuid == newComment.uuid);
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

  // Set a comment as the one being replied to
  void setReplyTo(Comment comment) {
    replyToComment.value = comment;
  }

  // Clear reply
  void clearReply() {
    replyToComment.value = null;
  }
}
