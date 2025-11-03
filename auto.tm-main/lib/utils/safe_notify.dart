import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Safe notification helper that avoids crashes when overlay/context not yet ready.
/// Falls back to logging-only if overlay missing during early app init.
class SafeNotify {
  static void snackbar(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    // If navigator key state not mounted yet, defer to next frame.
    final mounted = Get.key.currentState?.mounted ?? false;
    if (!mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Second attempt after a frame
        final stillMounted = Get.key.currentState?.mounted ?? false;
        if (!stillMounted) {
          // ignore: avoid_print
          print(
            '[SafeNotify] Suppressed snackbar (navigator not mounted): "$title" "$message"',
          );
          return;
        }
        Get.snackbar(
          title,
          message,
          snackPosition: position,
          backgroundColor: backgroundColor,
          colorText: colorText,
          duration: duration,
        );
      });
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration,
    );
  }
}

// SafeNotify end
