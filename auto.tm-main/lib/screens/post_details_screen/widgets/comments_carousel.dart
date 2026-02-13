import 'package:auto_tm/utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:auto_tm/domain/models/comment.dart';
import 'package:auto_tm/screens/post_details_screen/controller/comments_controller.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/comments.dart';
import 'package:auto_tm/utils/key.dart';

class CommentCarousel extends StatefulWidget {
  const CommentCarousel({super.key, required this.postId});
  final String postId;

  @override
  State<CommentCarousel> createState() => _CommentCarouselState();
}

class _CommentCarouselState extends State<CommentCarousel> {
  // Shared with CommentsPage when opened via "Show all"; same Get.put returns same instance for this post.
  late final CommentsController controller = Get.put(CommentsController());

  @override
  void initState() {
    super.initState();
    if (widget.postId.isNotEmpty) {
      controller.fetchComments(widget.postId);
    }
  }

  @override
  void didUpdateWidget(CommentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postId != oldWidget.postId && widget.postId.isNotEmpty) {
      controller.fetchComments(widget.postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (controller.comments.isEmpty) {
        return Text(
          'No comments yet'.tr,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        );
      }

      // Group replies under parents (single level flattening similar to full page)
      final all = controller.comments;
      final children = <String, List<Comment>>{};
      for (final c in all) {
        final rt = c.replyTo;
        if (rt != null) {
          children.putIfAbsent(rt, () => []).add(c);
        }
      }
      final roots = all.where((c) => c.replyTo == null).toList();
      roots.sort((a, b) {
        final at =
            DateTime.tryParse(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bt =
            DateTime.tryParse(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at); // newest first
      });

      int descendantCount(String rootId) {
        var count = 0;
        final stack = <String>[rootId];
        final visited = <String>{};
        while (stack.isNotEmpty) {
          final current = stack.removeLast();
          final list = children[current];
          if (list == null) continue;
          for (final ch in list) {
            final cid = ch.uuid;
            if (cid.isEmpty || visited.contains(cid)) continue;
            visited.add(cid);
            count += 1;
            stack.add(cid);
          }
        }
        return count;
      }

      // Take up to 3 recent roots for preview
      final previewRoots = roots.take(3).toList();

      return Column(
        children: [
          for (final root in previewRoots)
            _PreviewCommentCard(
              root: root,
              replies: children[root.uuid] ?? const [],
              totalReplies: descendantCount(root.uuid),
              onReply: () {
                // Navigate to full comments page focusing reply to this root
                Get.to(
                  () => const CommentsPage(),
                  arguments: {'postId': widget.postId, 'replyTo': root},
                );
              },
            ),
          if (roots.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${roots.length - 3} more'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _PreviewCommentCard extends StatelessWidget {
  const _PreviewCommentCard({
    required this.root,
    required this.replies,
    required this.totalReplies,
    required this.onReply,
  });
  final Comment root;
  final List<Comment> replies;
  final int totalReplies;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAtRaw = root.createdAt;
    String date = '';
    if (createdAtRaw.isNotEmpty) {
      try {
        date = DateFormat('MM/dd/yyyy').format(DateTime.parse(createdAtRaw));
      } catch (_) {}
    }
    final sender = root.userName ?? 'user';
    final message = root.message;
    final avatarPath = root.userAvatar;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.opacityCompat(.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.opacityCompat(.3),
          width: .7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(theme, avatarPath, sender),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '@$sender',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton(
                onPressed: onReply,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Reply'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (totalReplies > 0)
                Text(
                  '• ${'$totalReplies replies'.tr}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, String? avatarPath, String sender) {
    if (avatarPath != null && avatarPath.trim().isNotEmpty) {
      final full = avatarPath.startsWith('http')
          ? avatarPath
          : '${ApiKey.ip}$avatarPath';
      return CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(full),
        onBackgroundImageError: (_, _) {},
      );
    }
    // Fallback initials
    final initial = sender.isNotEmpty ? sender[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
