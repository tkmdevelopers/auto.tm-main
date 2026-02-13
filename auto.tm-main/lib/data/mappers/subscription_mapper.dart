import 'package:auto_tm/data/dtos/subscription_dto.dart';
import 'package:auto_tm/domain/models/subscription.dart';

class SubscriptionMapper {
  static Subscription fromDto(SubscriptionDto dto) {
    return Subscription(
      uuid: dto.uuid ?? '',
      title: Map<String, String>.from(dto.name ?? {}),
      description: Map<String, String>.from(dto.description ?? {}),
      price: dto.price?.toInt() ?? 0,
      color: dto.color ?? '',
      iconPath: _extractIconPath(dto.photo),
    );
  }

  static String _extractIconPath(Map<String, dynamic>? photo) {
    if (photo == null) return '';
    final path = photo['path'];
    if (path is Map && path['small'] is String) {
      return path['small'];
    }
    return '';
  }
}
