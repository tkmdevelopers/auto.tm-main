import 'package:auto_tm/data/dtos/subscription_dto.dart';
import 'package:auto_tm/data/mappers/subscription_mapper.dart';
import 'package:auto_tm/domain/models/subscription.dart';
import 'package:auto_tm/domain/repositories/subscription_repository.dart';
import 'package:auto_tm/services/network/api_client.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepositoryImpl(this._apiClient);

  @override
  Future<List<Subscription>> fetchSubscriptions() async {
    try {
      final response = await _apiClient.dio.get('subscription');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => SubscriptionMapper.fromDto(SubscriptionDto.fromJson(e)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> submitSubscription(SubscriptionRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        'subscription',
        data: {
          'location': request.location,
          'phone': request.phone,
          'subscriptionId': request.subscriptionUuid,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
