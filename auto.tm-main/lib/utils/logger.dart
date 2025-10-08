import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Lightweight centralized logger to replace scattered print() calls.
///
/// In debug/profile builds it forwards to dart:developer.log so IDE tooling
/// (observatory / DevTools) can pick up structured logs. In release it becomes
/// a no-op (unless force parameter used for critical errors).
class AppLogger {
  AppLogger._();

  static const String _appName = 'auto.tm';

  static void d(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(message, name: name ?? '$_appName:DEBUG');
      // Mirror to print for environments that don't display developer.log
      // (some physical devices / filtered logcat configurations)
      // ignore: avoid_print
      print('[DEBUG] $message');
    }
  }

  static void i(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(message, name: name ?? '$_appName:INFO');
      // ignore: avoid_print
      print('[INFO] $message');
    }
  }

  static void w(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? '$_appName:WARN',
        error: error,
        stackTrace: stackTrace,
      );
      // ignore: avoid_print
      print('[WARN] $message');
    }
  }

  static void e(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    bool force = false,
  }) {
    if (kDebugMode || force) {
      developer.log(
        message,
        name: name ?? '$_appName:ERROR',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      // ignore: avoid_print
      print('[ERROR] $message');
    }
  }
}
