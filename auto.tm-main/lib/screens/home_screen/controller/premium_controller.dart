import 'package:auto_tm/domain/models/subscription.dart';
import 'package:auto_tm/domain/repositories/subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PremiumController extends GetxController {
  var subscriptions = <Subscription>[].obs;
  var selectedId = ''.obs;
  final TextEditingController location = TextEditingController();
  final FocusNode locationFocus = FocusNode();
  final TextEditingController phone = TextEditingController();
  final FocusNode phoneFocus = FocusNode();

  SubscriptionRepository get _subscriptionRepository =>
      Get.find<SubscriptionRepository>();

  @override
  void onInit() {
    super.onInit();
    fetchSubscriptions();
  }

  void fetchSubscriptions() async {
    final result = await _subscriptionRepository.fetchSubscriptions();
    subscriptions.value = result;
  }

  void submitSubscription() async {
    final request = SubscriptionRequest(
      location: location.text,
      phone: phone.text,
      subscriptionUuid: selectedId.value,
    );

    final success = await _subscriptionRepository.submitSubscription(request);
    if (success) {
      Get.snackbar('Success', 'Subscription sent!');
    } else {
      Get.snackbar('Error', 'Failed to submit');
    }
  }
}
