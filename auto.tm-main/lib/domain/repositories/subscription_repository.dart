import 'package:auto_tm/domain/models/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> fetchSubscriptions();
  Future<bool> submitSubscription(SubscriptionRequest request);
}
