import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/upload_manager.dart';
import '../controller/post_controller.dart';
// upload_progress_screen deprecated and removed.

/// Global inline banner that surfaces current upload state.
/// Appears while an UploadTask exists (active, failed/cancelled retryable, or just completed)
/// and collapses away once cleared/discarded.
class UploadStatusBanner extends StatelessWidget {
  const UploadStatusBanner({
    super.key,
    this.compactWhenCompleted = true,
    this.hideOnCompletedAfter = const Duration(seconds: 3),
  });
  final bool compactWhenCompleted;
  final Duration hideOnCompletedAfter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mgr = Get.isRegistered<UploadManager>()
        ? Get.find<UploadManager>()
        : null;
    if (mgr == null) return const SizedBox.shrink();
    return Obx(() {
      final task = mgr.currentTask.value;
      if (task == null) return const SizedBox.shrink();
      final failed = task.isFailed.value || task.isCancelled.value;
      final complete = task.isCompleted.value;

      // Auto-hide completed after timeout (once) if compactWhenCompleted
      if (complete && compactWhenCompleted) {
        Future.microtask(() async {
          await Future.delayed(hideOnCompletedAfter);
          // Only clear if still same completed task (user didn't navigate or retry)
          if (task.isCompleted.value && mgr.currentTask.value == task) {
            mgr.clearIfTerminal();
          }
        });
      }

      Color bg;
      Color outline;
      if (complete) {
        bg = Colors.green.withValues(alpha: 0.10);
        outline = Colors.green.withValues(alpha: 0.55);
      } else if (failed) {
        bg = Colors.red.withValues(alpha: 0.08);
        outline = Colors.red.withValues(alpha: 0.40);
      } else {
        bg = theme.colorScheme.surface;
        outline = theme.colorScheme.outline.withValues(alpha: 0.25);
      }

      final pct = (task.overallProgress.value * 100)
          .clamp(0, 100)
          .toStringAsFixed(0);
    final title = complete
      ? 'post_upload_success_title'.tr
      : failed
        ? (task.isCancelled.value
          ? 'post_upload_cancelled_hint'.tr
          : 'common_error'.tr)
        : 'post_upload_progress'.trParams({'percent': pct});
    final subtitle = complete
      ? 'post_upload_success_body'.tr
      : failed
        ? (task.error.value ?? '')
        : '${task.status.value}${task.etaDisplay.value == '--:--' ? '' : ' • ${task.etaDisplay.value}'}';

      Widget _actions() {
        if (complete) {
          return const SizedBox.shrink(); // no actions after success
        }
        if (failed) {
          return Row(
            children: [
              TextButton(
                onPressed: () {
                  final pc = Get.isRegistered<PostController>()
                      ? Get.find<PostController>()
                      : Get.put(PostController());
                  mgr.retryActive(pc);
                },
                child: Text('Retry'.tr),
              ),
              TextButton(
                onPressed: () => mgr.discardTerminal(),
                child: Text('Discard'.tr),
              ),
            ],
          );
        }
        // Active -> only Cancel now
        return TextButton(
          onPressed: () {
            if (!Get.isRegistered<PostController>()) Get.put(PostController());
            final pc = Get.find<PostController>();
            mgr.cancelActive(pc);
          },
          child: Text('Cancel'.tr),
        );
      }

      // active flag no longer needed (no tap navigation)
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          // Tap no longer navigates (progress screen deprecated)
          onTap: null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: outline, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 4.2,
                        value: failed || complete
                            ? 1
                            : task.overallProgress.value.clamp(0, 1),
                        valueColor: AlwaysStoppedAnimation(
                          failed
                              ? Colors.red
                              : (complete
                                    ? Colors.green
                                    : theme.colorScheme.primary),
                        ),
                        backgroundColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    Icon(
                      failed
                          ? Icons.error_outline
                          : complete
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      size: 20,
                      color: failed
                          ? Colors.red
                          : (complete
                                ? Colors.green
                                : theme.colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _SubtitleSwitcher(
                          text: subtitle.isEmpty ? ' '.tr : subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _actions(),
              ],
            ),
          ),
        ), // end GestureDetector
      ); // end AnimatedSize
    });
  }
}

/// Internal widget to assign unique, monotonic keys for subtitle transitions.
/// Avoids AnimatedSwitcher duplicate key crash when the same subtitle string
/// re-occurs while a previous instance (with identical value) is still animating out.
class _SubtitleSwitcher extends StatefulWidget {
  const _SubtitleSwitcher({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_SubtitleSwitcher> createState() => _SubtitleSwitcherState();
}

class _SubtitleSwitcherState extends State<_SubtitleSwitcher> {
  String? _lastValue;
  int _seq = 0;

  @override
  void didUpdateWidget(covariant _SubtitleSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _lastValue) {
      _lastValue = widget.text;
      _seq++; // new sequence for each distinct textual change
    }
  }

  @override
  void initState() {
    super.initState();
    _lastValue = widget.text;
  }

  @override
  Widget build(BuildContext context) {
    // Key combines value + sequence ensuring uniqueness even if value repeats later.
    final key = ValueKey('${_lastValue ?? ''}#$_seq');
    return Text(
      _lastValue ?? '',
      key: key,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}
