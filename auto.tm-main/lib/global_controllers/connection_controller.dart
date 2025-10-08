import 'package:auto_tm/global_widgets/no_internet_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectionController extends GetxController {
  RxBool hasConnection = true.obs;

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
          if (Get.currentRoute != '/no-internet') {
            Get.offAll(() => const NoInternetView());
          }
        } 
        if(hasConnection) {
          if (Get.currentRoute == '/no-internet') {
            Get.offAllNamed('/navview');
          }
        }
      }
    });
  }
}
