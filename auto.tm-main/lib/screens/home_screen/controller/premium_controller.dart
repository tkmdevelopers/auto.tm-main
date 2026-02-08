import 'package:auto_tm/screens/home_screen/model/premium_model.dart';
import 'package:auto_tm/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PremiumController extends GetxController {
  var subscriptions = <SubscriptionModel>[].obs;
  var selectedId = ''.obs;
  final TextEditingController location = TextEditingController();
  final FocusNode locationFocus = FocusNode();
  final TextEditingController phone = TextEditingController();
  final FocusNode phoneFocus = FocusNode();
  
  SubscriptionService get _subscriptionService => Get.find<SubscriptionService>();

  @override
  void onInit() {
    super.onInit(); //!toggle
    fetchSubscriptions();
  }

  void fetchSubscriptions() async {
    final result = await _subscriptionService.fetchSubscriptions();
    subscriptions.value = result;
  }

  void submitSubscription() async {
    final model = SubscriptionRequestModel(
      location: location.text,
      phone: phone.text,
      subscriptionId: selectedId.value,
    );

    final success = await _subscriptionService.submitSubscription(model);
    if (success) {
      Get.snackbar('Success', 'Subscription sent!');
    } else {
      Get.snackbar('Error', 'Failed to submit');
    }
  }
}
