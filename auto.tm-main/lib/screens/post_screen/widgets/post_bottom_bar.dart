import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/upload_manager.dart';

/// The fixed bottom action bar for the post form.
///
/// Contains a **Save** button, the main **Post** button, and a **Reset** icon.
///
/// All validation / gating callbacks are supplied by the parent so this widget
/// stays presentation-only.
class PostBottomBar extends StatelessWidget {
  const PostBottomBar({
    super.key,
    required this.postController,
    required this.onPost,
    required this.onUploadBlocked,
    required this.brandError,
    required this.modelError,
    required this.onValidationFailed,
  });

  final PostController postController;

  /// Called when the user presses **Post** and all preconditions pass.
  final VoidCallback onPost;

  /// Called when an active upload blocks a new post.
  final void Function(BuildContext context, UploadManager manager, UploadTask task)
      onUploadBlocked;

  /// Current brand / model validation errors (nullable).
  final String? brandError;
  final String? modelError;

  /// Called when brand / model validation fails so the parent can scroll.
  final void Function(String? brandErr, String? modelErr) onValidationFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Obx(() {
        final isPosting = postController.isPosting.value;
        final manager = Get.find<UploadManager>();
        final task = manager.currentTask.value;
        final locked = manager.isLocked.value;
        final failedOrCancelled = task != null && task.isFailed.value;
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: postController.hasAnyInput
                    ? () {
                        if (postController.isFormSaved.value &&
                            !postController.isDirty.value) {
                          Get.rawSnackbar(
                            message: 'No changes to save'.tr,
                            duration: const Duration(seconds: 2),
                          );
                          return;
                        }
                        final wasCompleteBefore = postController.hasMinimumData;
                        postController.saveForm();
                        final nowComplete = postController.hasMinimumData;
                        final msg = nowComplete
                            ? 'Form saved'.tr
                            : (wasCompleteBefore
                                ? 'Form saved (still complete)'.tr
                                : 'Partial form saved'.tr);
                        Get.rawSnackbar(
                          message: msg,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Obx(() {
                  final saved = postController.isFormSaved.value;
                  final dirty = postController.isDirty.value;
                  final label = saved
                      ? (dirty ? 'post_save_form'.tr : 'post_saved'.tr)
                      : 'post_save_form'.tr;
                  return Text(label);
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: isPosting
                    ? null
                    : () async {
                        // Inline validation
                        final bErr =
                            postController.selectedBrandUuid.value.isEmpty
                            ? 'Brand required'.tr
                            : null;
                        final mErr =
                            postController.selectedModelUuid.value.isEmpty
                            ? 'Model required'.tr
                            : null;
                        if (bErr != null || mErr != null) {
                          onValidationFailed(bErr, mErr);
                          return;
                        }
                        if (locked && task != null) {
                          onUploadBlocked(context, manager, task);
                          return;
                        }
                        if (!postController.isPhoneVerified.value) {
                          Get.snackbar(
                            'Error',
                            'You have to go through OTP verification.'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        onPost();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  disabledBackgroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  foregroundColor: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isPosting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Posting...'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : (locked && failedOrCancelled
                          ? Text(
                              'Resolve pending upload'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              'post_post_action'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Reset form'.tr,
              onPressed: (postController.hasAnyInput ||
                      postController.isFormSaved.value ||
                      postController.isDirty.value)
                  ? () {
                      final hadSaved = postController.isFormSaved.value;
                      postController.clearSavedForm();
                      postController.reset();
                      Get.rawSnackbar(
                        message:
                            hadSaved ? 'Form cleared'.tr : 'Form reset'.tr,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  : null,
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        );
      }),
    );
  }
}
