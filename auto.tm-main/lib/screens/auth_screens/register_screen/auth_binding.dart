import 'package:auto_tm/screens/auth_screens/register_screen/controller/register_controller.dart';
import 'package:auto_tm/screens/post_screen/controller/phone_verification_controller.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterPageController>(() => RegisterPageController());
    Get.lazyPut<PhoneVerificationController>(
      () => PhoneVerificationController(),
    );
  }
}
