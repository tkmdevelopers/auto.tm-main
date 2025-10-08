import 'dart:convert';

import 'package:auto_tm/screens/home_screen/model/premium_model.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PremiumController extends GetxController {
  var subscriptions = <SubscriptionModel>[].obs;
  var selectedId = ''.obs;
  final TextEditingController location = TextEditingController();
  final FocusNode locationFocus = FocusNode();
  final TextEditingController phone = TextEditingController();
  final FocusNode phoneFocus = FocusNode();

  @override
  void onInit() {
    super.onInit(); //!toggle
    fetchSubscriptions();
  }

  void fetchSubscriptions() async {
    final response = await http.get(Uri.parse(ApiKey.getPremiumKey));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      subscriptions.value = data
          .map((e) => SubscriptionModel.fromJson(e))
          .toList();
      // print(data);
    } else {
      ("Error", "Failed to load subscriptions");
    }
  }

  void submitSubscription() async {
    final model = SubscriptionRequestModel(
      location: location.text,
      phone: phone.text,
      subscriptionId: selectedId.value,
    );

    final response = await http.post(
      Uri.parse(ApiKey.postPremiumKey),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(model.toJson()),
    );

    if (response.statusCode == 200) {
      ("Success", "Subscription sent!");
    } else {
      ("Error", "Failed to submit");
    }
  }
}
