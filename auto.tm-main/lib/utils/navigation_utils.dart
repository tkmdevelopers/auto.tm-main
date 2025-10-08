import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centralized navigation helpers to avoid Get.back() snackbar side-effects
/// and provide simple tap throttling.
class NavigationUtils {
  NavigationUtils._();

  /// Safely pop the top-most route (bottom sheet, dialog, or page) without
  /// triggering GetX snackbar controller race conditions.
  static void safePop<T extends Object?>(BuildContext context, {T? result}) {
    close<T>(context, result: result);
  }

  /// Unified close semantics that attempts (in order):
  /// 1. If a dialog or bottom sheet is open, pop that overlay.
  /// 2. Else pop the current Navigator (non-root) if possible.
  /// 3. Else pop the rootNavigator if possible.
  /// 4. Else (last resort) call Get.back() only if Get's navigator can pop.
  /// Avoids directly triggering snackbar controller teardown when none exists.
  static void close<T extends Object?>(BuildContext context, {T? result}) {
    if (_debug) debugPrint('[NavigationUtils.close] start result=$result');
    // 1. Dialog / BottomSheet overlays (prefer rootNavigator for modals)
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      try {
        final root = Navigator.of(context, rootNavigator: true);
        if (root.canPop()) {
          root.pop<T>(result);
          if (_debug)
            debugPrint(
              '[NavigationUtils.close] overlay popped via rootNavigator',
            );
          return;
        }
      } catch (_) {
        // Fallback to Get
        try {
          if (Get.key.currentState?.canPop() ?? false) {
            // Guard snackbar path
            if (Get.isSnackbarOpen == true) {
              if (_debug)
                debugPrint(
                  '[NavigationUtils.close] fallback Get.back with snackbar',
                );
              Get.back<T>(result: result);
            } else {
              Get.back<T>(result: result);
              if (_debug)
                debugPrint('[NavigationUtils.close] fallback Get.back overlay');
            }
            return;
          }
        } catch (_) {}
      }
    }

    // 2. Current (nearest) Navigator
    try {
      final localNav = Navigator.of(context);
      if (localNav.canPop()) {
        localNav.pop<T>(result);
        if (_debug) debugPrint('[NavigationUtils.close] local navigator pop');
        return;
      }
    } catch (_) {}

    // 3. Root Navigator (in case previous wasn't root and stack lives there)
    try {
      final rootNav = Navigator.of(context, rootNavigator: true);
      if (rootNav.canPop()) {
        rootNav.pop<T>(result);
        if (_debug) debugPrint('[NavigationUtils.close] root navigator pop');
        return;
      }
    } catch (_) {}

    // 4. Get fallback only if its navigator can pop
    try {
      if (Get.key.currentState?.canPop() ?? false) {
        if (Get.isSnackbarOpen == true) {
          if (_debug)
            debugPrint('[NavigationUtils.close] Get.back with snackbar open');
          Get.back<T>(result: result);
        } else {
          try {
            Get.back<T>(result: result);
            if (_debug) debugPrint('[NavigationUtils.close] Get.back fallback');
          } catch (_) {}
        }
      }
    } catch (_) {}
    if (_debug) debugPrint('[NavigationUtils.close] no action');
  }

  /// Close without an explicit context (controller usage).
  static void closeGlobal<T extends Object?>({T? result}) {
    final ctx = Get.key.currentContext;
    if (ctx != null) {
      close<T>(ctx, result: result);
      return;
    }
    try {
      if (Get.key.currentState?.canPop() ?? false) {
        if (Get.isSnackbarOpen == true) {
          Get.back<T>(result: result);
        } else {
          Get.back<T>(result: result);
        }
      }
    } catch (_) {}
  }

  /// Prime a snackbar at app start (optional) to initialize GetX's snackbar
  /// controller lifecycle and avoid late init errors later.
  static void primeSnackbarOnce() {
    if (_primed) return;
    _primed = true;
    // Use a post-frame callback to ensure overlay exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;
      Get.rawSnackbar(
        // very short lived, mostly invisible
        message: '',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 10),
        backgroundColor: Colors.transparent,
        overlayBlur: 0,
        snackStyle: SnackStyle.FLOATING,
      );
    });
  }

  static bool _primed = false;

  /// Simple tap throttle to prevent double taps firing within a window.
  static bool throttle(
    String key, {
    Duration window = const Duration(milliseconds: 400),
  }) {
    final now = DateTime.now();
    final last = _lastTap[key];
    if (last != null && now.difference(last) < window) {
      return false; // reject tap
    }
    _lastTap[key] = now;
    return true; // accept
  }

  static final Map<String, DateTime> _lastTap = {};
  static bool _debug = false; // toggle for verbose navigation logs
}
