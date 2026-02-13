import 'package:auto_tm/utils/color_extensions.dart';
// Temporary clean replacement version to avoid patch collisions. After verifying, rename to comments.dart.
import 'package:auto_tm/domain/models/comment.dart';
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
  Comment? initialReplyTarget;

  // Scroll + focus handling
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _highlightCommentId; // uuid of comment to highlight
  bool _didInitialScroll = false; // ensure we only auto-scroll once

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is String) {
      uuid = args;
    } else if (args is Map) {
      uuid = args['postId']?.toString() ?? '';
      final rt = args['replyTo'];
      if (rt is Comment) initialReplyTarget = rt;
    } else {
      uuid = '';
    }

    Future.microtask(() async {
      await controller.fetchComments(uuid);
      if (initialReplyTarget != null) {
        controller.setReplyTo(initialReplyTarget!);
        _highlightCommentId = initialReplyTarget!.uuid;
        // Delay focus until first frame built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _commentFocusNode.requestFocus();
          setState(() {}); // trigger rebuild for highlight usage
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text(
          'Comments'.tr,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
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
                  child: Text(
                    'No comments yet'.tr,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }
              // Flatten to single-level replies: show all descendants at depth 1 when expanded
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
                return at.compareTo(bt);
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
                    if (visited.contains(cid)) continue;
                    visited.add(cid);
                    count += 1;
                    stack.add(cid);
                  }
                }
                return count;
              }

              List<Comment> collectDescendants(String rootId) {
                final flat = <Comment>[];
                final stack = <String>[rootId];
                final visited = <String>{};
                while (stack.isNotEmpty) {
                  final current = stack.removeLast();
                  final list = children[current];
                  if (list == null) continue;
                  // sort each sibling batch chronologically
                  list.sort((a, b) {
                    final at =
                        DateTime.tryParse(a.createdAt) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bt =
                        DateTime.tryParse(b.createdAt) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return at.compareTo(bt);
                  });
                  for (final ch in list) {
                    final cid = ch.uuid;
                    if (visited.contains(cid)) continue;
                    visited.add(cid);
                    flat.add(ch);
                    stack.add(cid);
                  }
                }
                return flat;
              }

              final display =
                  <
                    ({
                      Comment comment,
                      int depth,
                      bool isParent,
                      int repliesCount,
                      bool expanded,
                      VoidCallback? toggle,
                    })
                  >[];
              for (final root in roots) {
                final rootId = root.uuid;
                final totalReplies = descendantCount(rootId);
                final expanded = controller.isThreadExpanded(rootId);
                display.add((
                  comment: root,
                  depth: 0,
                  isParent: true,
                  repliesCount: totalReplies,
                  expanded: expanded,
                  toggle: totalReplies > 0
                      ? () => controller.toggleThread(rootId)
                      : null,
                ));
                if (expanded && totalReplies > 0) {
                  final desc = collectDescendants(rootId);
                  for (final r in desc) {
                    display.add((
                      comment: r,
                      depth: 1,
                      isParent: false,
                      repliesCount: 0,
                      expanded: false,
                      toggle: null,
                    ));
                  }
                }
              }

              // Attempt to find highlight index once comments are built
              if (_highlightCommentId != null && !_didInitialScroll) {
                final targetIndex = display.indexWhere(
                  (e) => e.comment.uuid == _highlightCommentId,
                );
                if (targetIndex >= 0) {
                  _didInitialScroll = true; // prevent repeated attempts
                  // Scroll after current frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_scrollController.hasClients) return;
                    final offset =
                        targetIndex * 112.0; // rough row height estimate
                    _scrollController.animateTo(
                      offset.clamp(
                        0,
                        _scrollController.position.maxScrollExtent,
                      ),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                    );
                  });
                }
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: display.length,
                itemBuilder: (context, index) {
                  final row = display[index];
                  final isHighlight = row.comment.uuid == _highlightCommentId;
                  return _CommentItem(
                    comment: row.comment,
                    onReply: () {
                      controller.setReplyTo(row.comment);
                      _highlightCommentId = row.comment.uuid;
                      // focus input
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _commentFocusNode.requestFocus();
                      });
                      setState(() {});
                    },
                    isParent: row.isParent,
                    depth: row.depth,
                    repliesCount: row.repliesCount,
                    expanded: row.expanded,
                    onToggleReplies: row.toggle,
                    highlight: isHighlight,
                  );
                },
              );
            }),
          ),
          Obx(
            () => controller.replyToComment.value != null
                ? _ReplyBanner(
                    message: controller.replyToComment.value!.message,
                    onCancel: controller.clearReply,
                  )
                : const SizedBox.shrink(),
          ),
          _CommentInputBar(
            controller: controller,
            postUuid: uuid,
            focusNode: _commentFocusNode,
          ),
        ],
      ),
    );
  }
}

// Root resolution helper no longer needed after flattening to single-level replies.

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    required this.comment,
    required this.onReply,
    this.depth = 0,
    this.isParent = false,
    this.repliesCount = 0,
    this.expanded = false,
    this.onToggleReplies,
    this.highlight = false,
  });
  final Comment comment;
  final VoidCallback onReply;
  final int depth; // nesting level (0 parent, 1 reply)
  final bool isParent;
  final int repliesCount;
  final bool expanded;
  final VoidCallback? onToggleReplies;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAtRaw = comment.createdAt;
    String timeText = '';
    if (createdAtRaw.isNotEmpty) {
      try {
        timeText = DateFormat(
          'MM.dd.yyyy | HH:mm',
        ).format(DateTime.parse(createdAtRaw));
      } catch (_) {}
    }
    final isReply = (comment.replyTo != null);
    final parentSender =
        ''; // PostRepository could potentially resolve this or we add it to model
    final sender = comment.userName ?? 'user';
    final message = comment.message;
    final avatarPath = comment.userAvatar;
    // Debug logging removed after verification of avatar path handling.

    final indent = depth * 28.0;

    final baseColor = theme.colorScheme.surfaceContainerHighest.opacityCompat(
      0.28,
    );
    final highlightStart = theme.colorScheme.primary.opacityCompat(0.35);
    return GestureDetector(
      onLongPress: onReply,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          begin: highlight ? highlightStart : baseColor,
          end: baseColor,
        ),
        duration: highlight
            ? const Duration(milliseconds: 1300)
            : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, color, child) => Container(
          margin: EdgeInsets.fromLTRB(12 + indent, 4, 12, 4),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          constraints: const BoxConstraints(maxWidth: 900),
          decoration: BoxDecoration(
            color: color ?? baseColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.opacityCompat(.35),
              width: 0.7,
            ),
          ),
          child: child,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReply)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'Replying to '.tr),
                      if (parentSender.isNotEmpty)
                        TextSpan(
                          text: '@$parentSender',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      if (parentSender.isEmpty) const TextSpan(text: '...'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (avatarPath != null)
                  ProfileAvatar(
                    remotePath: avatarPath,
                    radius: 16,
                    backgroundRadiusDelta: 2,
                    iconSize: 16,
                  )
                else
                  _InitialsAvatar(name: sender, radius: 16),
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
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isParent && repliesCount > 0)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary
                            .opacityCompat(.08),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      onPressed: onToggleReplies,
                      icon: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        expanded
                            ? 'comments_thread_hide'.trParams({
                                'count': repliesCount.toString(),
                              })
                            : 'comments_thread_view'.trParams({
                                'count': repliesCount.toString(),
                              }),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.1,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 0,
                      ),
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
                ],
              ),
            ),
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
        color: theme.colorScheme.surfaceContainerHighest.opacityCompat(.6),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.opacityCompat(.4),
            width: .7,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ('${'comments_replying_to_prefix'.tr} ') +
                  (message.length > 40
                      ? '${message.substring(0, 40)}…'
                      : message),
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
  const _CommentInputBar({
    required this.controller,
    required this.postUuid,
    this.focusNode,
  });
  final CommentsController controller;
  final String postUuid;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        // Subtle top separator + background blending
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.opacityCompat(.25),
              width: .7,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: TextField(
            controller: controller.commentTextController,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 5,
            style: TextStyle(
              fontSize: 14.5,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .opacityCompat(.55),
              hintText: 'comments_add_placeholder'.tr,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.opacityCompat(.65),
                fontSize: 14,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  tooltip: 'Send'.tr,
                  splashRadius: 22,
                  onPressed: () async {
                    final text = controller.commentTextController.text.trim();
                    if (text.isEmpty) return;
                    await controller.sendComment(postUuid, text);
                    controller.commentTextController.clear();
                  },
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minHeight: 40,
                minWidth: 40,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.opacityCompat(.35),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.opacityCompat(.65),
                  width: 1.1,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.opacityCompat(.35),
                  width: 0.8,
                ),
              ),
            ),
            textInputAction: TextInputAction.newline,
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.radius = 16});
  final String name;
  final double radius;

  String _initials(String input) {
    final parts = input
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txt = _initials(name);
    return CircleAvatar(
      radius: radius + 2,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          txt,
          style: TextStyle(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
