/// Factory for creating Post test data
class PostFactory {
  static Map<String, dynamic> makeJson({
    String? uuid,
    String? brand,
    String? model,
    String? brandId,
    String? modelId,
    double? price,
    String? photoPath,
    double? year,
    double? milleage,
    String? currency,
    String? createdAt,
    bool? status,
  }) {
    return {
      'uuid': uuid ?? 'post_${DateTime.now().millisecondsSinceEpoch}',
      'brand': brand ?? 'Toyota',
      'model': model ?? 'Camry',
      'brandsId': brandId ?? 'brand_123',
      'modelsId': modelId ?? 'model_456',
      'price': price ?? 25000.0,
      'photoPath': photoPath ?? 'uploads/post_123/photo_1.jpg',
      'year': year ?? 2023.0,
      'milleage': milleage ?? 50000.0,
      'currency': currency ?? 'USD',
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'status': status ?? true,
      'brands': {'uuid': brandId ?? 'brand_123', 'name': brand ?? 'Toyota'},
      'models': {'uuid': modelId ?? 'model_456', 'name': model ?? 'Camry'},
      'photo': [
        {
          'path': {
            'small': 'uploads/post_123/small.jpg',
            'medium': 'uploads/post_123/medium.jpg',
            'large': 'uploads/post_123/large.jpg',
            'originalPath': photoPath ?? 'uploads/post_123/photo_1.jpg',
          },
        },
      ],
    };
  }

  /// Create a list of posts
  static List<Map<String, dynamic>> makeList({int count = 5}) {
    return List.generate(
      count,
      (index) => makeJson(
        uuid: 'post_$index',
        brand: ['Toyota', 'BMW', 'Mercedes', 'Audi', 'Honda'][index % 5],
        model: ['Camry', 'X5', 'E-Class', 'A4', 'Accord'][index % 5],
        price: 20000.0 + (index * 5000),
        year: 2020.0 + index,
      ),
    );
  }

  /// Create a post for "my posts" endpoint (user's own posts)
  static Map<String, dynamic> makeMyPostJson({String? uuid, bool? status}) {
    return makeJson(uuid: uuid, status: status);
  }
}
