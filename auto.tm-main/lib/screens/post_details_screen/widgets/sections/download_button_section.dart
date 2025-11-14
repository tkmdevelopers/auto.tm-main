import 'package:auto_tm/global_controllers/download_controller.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Section for downloading PDF diagnostics with progress indicator
class DownloadButtonSection extends StatelessWidget {
  final Post post;
  final DownloadController downloadController;
  final ThemeData theme;

  const DownloadButtonSection({
    super.key,
    required this.post,
    required this.downloadController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if file exists
    if (post.file?.path.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final controller = downloadController;

        if (controller.isDownloading.value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: controller.progress.value / 100,
              ),
              const SizedBox(height: 8),
              Text(
                "Downloading... ${controller.progress.value}%",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }

        // Download button
        return ElevatedButton.icon(
          icon: Icon(
            Icons.download,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          label: Text(
            "Download car diagnostics".tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onPressed: () {
            final fileName =
                "AutoTM_${post.brand}_${post.model}_${post.year.toStringAsFixed(0)}.pdf";
            final fullUrl = "${ApiKey.ip}${post.file!.path}";
            controller.startDownload(fullUrl, fileName);
          },
        );
      }),
    );
  }
}
