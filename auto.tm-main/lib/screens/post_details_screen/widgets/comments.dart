// Temporary clean replacement version to avoid patch collisions. After verifying, rename to comments.dart.
import 'package:auto_tm/screens/post_details_screen/controller/comments_controller.dart';
import 'package:auto_tm/screens/profile_screen/widgets/profile_avatar.dart';
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
  late final String uuid;

  @override
  void initState() {
    super.initState();
    uuid = Get.arguments;
    Future.microtask(() => controller.fetchComments(uuid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text('Comments'.tr,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            )),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.comments.isEmpty) {
                return Center(
                  child: Text('No comments yet'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return _CommentItem(
                    comment: comment,
                    onReply: () => controller.setReplyTo(comment),
                  );
                },
              );
            }),
          ),
          Obx(() => controller.replyToComment.value != null
              ? _ReplyBanner(
                  message: controller.replyToComment.value!['message'] ?? '',
                  onCancel: controller.clearReply,
                )
              : const SizedBox.shrink()),
          _CommentInputBar(controller: controller, postUuid: uuid),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({required this.comment, required this.onReply});
  final Map<String, dynamic> comment;
  final VoidCallback onReply;

  String? _extractAvatarPath(Map<String, dynamic> c) {
    try {
      final user = c['user'];
      if (user is Map) {
        final avatar = user['avatar'];
        if (avatar is Map) {
          final variants = avatar['variants'] ?? avatar['paths'] ?? avatar['avatarVariants'];
          if (variants is Map) {
            final medium = variants['medium'] ?? variants['large'] ?? variants['small'] ?? variants['path'];
            if (medium is String) return medium;
          }
          if (avatar['path'] is String) return avatar['path'];
        }
        if (user['avatarPath'] is String) return user['avatarPath'];
      }
      if (c['avatar'] is String) return c['avatar'];
      if (c['avatarPath'] is String) return c['avatarPath'];
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAtRaw = comment['createdAt'];
    String timeText = '';
    if (createdAtRaw is String) {
      try {
        timeText = DateFormat('MM.dd.yyyy | HH:mm').format(DateTime.parse(createdAtRaw));
      } catch (_) {}
    }
    final isReply = comment.containsKey('replyTo') && comment['replyTo'] != null;
    final sender = comment['sender']?.toString() ?? 'user';
    final message = comment['message']?.toString() ?? '';
    final avatarPath = _extractAvatarPath(comment);

    return GestureDetector(
      onLongPress: onReply,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(.4),
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReply)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Replying to…',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfileAvatar(
                  remotePath: avatarPath,
                  radius: 16,
                  backgroundRadiusDelta: 2,
                  iconSize: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '@$sender',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (timeText.isNotEmpty)
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.28,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: theme.colorScheme.primary,
                ),
                onPressed: onReply,
                icon: Icon(
                  Icons.reply_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  'Reply'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.message, required this.onCancel});
  final String message;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.6),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(.4),
            width: .7,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Replying to: ' + (message.length > 40 ? message.substring(0, 40) + '…' : message),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({required this.controller, required this.postUuid});
  final CommentsController controller;
  final String postUuid;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(.4),
                    width: .7,
                  ),
                ),
                child: TextField(
                  controller: controller.commentTextController,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Add a comment'.tr,
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(.7)),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, size: 18),
                color: theme.colorScheme.onPrimary,
                splashRadius: 22,
                onPressed: () async {
                  final text = controller.commentTextController.text.trim();
                  if (text.isEmpty) return;
                  await controller.sendComment(postUuid, text);
                  controller.commentTextController.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
