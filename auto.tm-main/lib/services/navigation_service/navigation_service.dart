import 'package:get/get.dart';
import 'package:auto_tm/utils/logger.dart';

/// Centralized navigation service for consistent routing throughout the app.
/// Provides type-safe navigation methods and handles edge cases.
class NavigationService {
  NavigationService._();

  // ==================== Auth Flow ====================

  /// Navigate to registration (phone number input) screen
  static void toRegister({String? from}) {
    AppLogger.d('Navigating to register from: $from');
    Get.toNamed('/register');
  }

  /// Navigate to OTP verification screen
  static void toOtp() {
    AppLogger.d('Navigating to OTP screen');
    Get.toNamed('/checkOtp');
  }

  // ==================== Main App Flow ====================

  /// Navigate to main navigation view (home screen by default)
  static void toHome({bool clearStack = false}) {
    AppLogger.d('Navigating to home, clearStack: $clearStack');
    if (clearStack) {
      Get.offAllNamed('/navView');
    } else {
      Get.toNamed('/navView');
    }
  }

  /// Navigate to profile screen
  static void toProfile() {
    AppLogger.d('Navigating to profile');
    Get.toNamed('/profile');
  }

  /// Navigate to filter screen
  static void toFilter() {
    AppLogger.d('Navigating to filter');
    Get.toNamed('/filter');
  }

  /// Navigate to search screen
  static void toSearch() {
    AppLogger.d('Navigating to search');
    Get.toNamed('/search');
  }

  // ==================== Navigation Utilities ====================

  /// Go back to previous screen
  /// Returns true if navigation was successful, false if no more screens to pop
  static bool back<T>({T? result}) {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<T>(result: result);
      AppLogger.d('Navigated back');
      return true;
    }
    AppLogger.w('Cannot navigate back - no screens to pop');
    return false;
  }

  /// Pop until a specific named route
  /// Returns true if the route was found, false otherwise
  static bool popUntil(String routeName) {
    try {
      bool found = false;
      Get.until((route) {
        if (route.settings.name == routeName) {
          found = true;
          return true;
        }
        return false;
      });

      if (found) {
        AppLogger.d('Popped until route: $routeName');
      } else {
        AppLogger.w('Route not found in stack: $routeName');
      }

      return found;
    } catch (e) {
      AppLogger.e('Error popping until route', error: e);
      return false;
    }
  }

  /// Clear navigation stack and go to a specific route
  static void clearStackAndGoTo(String routeName) {
    AppLogger.d('Clearing stack and navigating to: $routeName');
    Get.offAllNamed(routeName);
  }

  /// Check if a specific route exists in the navigation stack
  static bool isRouteInStack(String routeName) {
    try {
      bool found = false;
      Get.key.currentState?.popUntil((route) {
        if (route.settings.name == routeName) {
          found = true;
        }
        return true; // Don't actually pop, just check
      });
      return found;
    } catch (e) {
      AppLogger.w('Error checking route in stack', error: e);
      return false;
    }
  }

  /// Get current route name
  static String get currentRoute => Get.currentRoute;

  /// Check if we can navigate back
  static bool get canPop => Get.key.currentState?.canPop() ?? false;

  /// Safe navigation with error handling
  /// Returns true if navigation succeeded, false otherwise
  static Future<bool> safeNavigate(
    Future<dynamic> Function() navigationAction,
  ) async {
    try {
      await navigationAction();
      return true;
    } catch (e, st) {
      AppLogger.e('Navigation failed', error: e, stackTrace: st);
      return false;
    }
  }

  // ==================== Auth Guards ====================

  /// Check if user needs authentication and redirect to register if needed
  /// Returns true if user is authenticated, false if redirected to register
  static bool requireAuth() {
    // This will be implemented based on your token service
    // For now, returning true as placeholder
    return true;
  }

  /// Navigate to login/register with return path
  static void toAuthWithReturn(String returnPath) {
    AppLogger.d('Navigating to auth with return path: $returnPath');
    Get.toNamed('/register', arguments: {'returnPath': returnPath});
  }

  // ==================== Debug Utilities ====================

  /// Print current navigation stack (debug only)
  static void debugPrintStack() {
    if (kDebugMode) {
      AppLogger.d('Current route: ${Get.currentRoute}');
      AppLogger.d('Previous route: ${Get.previousRoute}');
      AppLogger.d('Can pop: ${Get.key.currentState?.canPop()}');
    }
  }
}

// Flag to enable debug mode
const bool kDebugMode = true; // Set to false in production
