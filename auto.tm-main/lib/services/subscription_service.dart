import 'package:auto_tm/screens/home_screen/model/premium_model.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get/get.dart';

/// Service for handling subscription/premium-related API calls.
/// This keeps networking logic out of controllers.
class SubscriptionService extends GetxService {
  final ApiClient _apiClient;

  SubscriptionService(this._apiClient);

  /// Fetch all available subscription plans
  Future<List<SubscriptionModel>> fetchSubscriptions() async {
    try {
      final response = await _apiClient.dio.get('subscription');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          return data
              .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      Get.log('Error fetching subscriptions: $e');
      return [];
    }
  }

  /// Submit a subscription request
  Future<bool> submitSubscription(SubscriptionRequestModel request) async {
    try {
      final response = await _apiClient.dio.post(
        'subscription',
        data: request.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      Get.log('Error submitting subscription: $e');
      return false;
    }
  }
}
