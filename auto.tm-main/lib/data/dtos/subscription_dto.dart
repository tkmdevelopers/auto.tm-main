class SubscriptionDto {
  final String? uuid;
  final Map<String, dynamic>? name;
  final Map<String, dynamic>? description;
  final num? price;
  final String? color;
  final Map<String, dynamic>? photo;

  SubscriptionDto({
    this.uuid,
    this.name,
    this.description,
    this.price,
    this.color,
    this.photo,
  });

  factory SubscriptionDto.fromJson(Map<String, dynamic> json) {
    return SubscriptionDto(
      uuid: json['uuid'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      color: json['color'],
      photo: json['photo'],
    );
  }
}
