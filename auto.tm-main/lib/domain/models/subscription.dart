class Subscription {
  final String uuid;
  final Map<String, String> title;
  final Map<String, String> description;
  final int price;
  final String color;
  final String iconPath;

  Subscription({
    required this.uuid,
    required this.title,
    required this.description,
    required this.price,
    required this.color,
    required this.iconPath,
  });

  String getLocalizedTitle(String locale) => title[locale] ?? title['en'] ?? 'Unnamed';
  String getLocalizedDescription(String locale) => description[locale] ?? description['en'] ?? '';
}

class SubscriptionRequest {
  final String location;
  final String phone;
  final String subscriptionUuid;

  SubscriptionRequest({
    required this.location,
    required this.phone,
    required this.subscriptionUuid,
  });
}
