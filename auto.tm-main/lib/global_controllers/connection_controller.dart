import 'package:auto_tm/global_widgets/no_internet_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectionController extends GetxController {
  RxBool hasConnection = true.obs;
  String? _previousRoute;

  @override
  void onInit() {
    super.onInit();
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasConnection != this.hasConnection.value) {
        this.hasConnection.value = hasConnection;

        if (!hasConnection) {
          // Store the current route before showing no internet screen
          if (Get.currentRoute != '/no-internet') {
            _previousRoute = Get.currentRoute;
            Get.offAll(() => const NoInternetView());
          }
        } else {
          // Connection restored
          if (Get.currentRoute == '/no-internet') {
            debugPrint('[Connection] Internet restored, returning to app');
            // Navigate back to the previous route or default to /navView
            final routeToRestore = _previousRoute ?? '/navView';
            _previousRoute = null;

            // Navigate back
            Get.offAllNamed(routeToRestore);

            // Show a brief success message
            Future.delayed(const Duration(milliseconds: 500), () {
              Get.snackbar(
                'Connected',
                'Internet connection restored',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
                backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.9),
                colorText: Get.theme.colorScheme.onPrimary,
                margin: const EdgeInsets.all(16),
                borderRadius: 8,
              );
            });
          }
        }
      }
    });
  }
}
