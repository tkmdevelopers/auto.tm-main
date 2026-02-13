/// Factory for creating Brand test data
class BrandFactory {
  static Map<String, dynamic> makeJson({String? uuid, String? name}) {
    return {
      'uuid': uuid ?? 'brand_${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Toyota',
    };
  }

  /// Create a list of brands
  static List<Map<String, dynamic>> makeList({int count = 10}) {
    final brandNames = [
      'Toyota',
      'BMW',
      'Mercedes',
      'Audi',
      'Honda',
      'Ford',
      'Chevrolet',
      'Nissan',
      'Hyundai',
      'Kia',
    ];
    return List.generate(
      count,
      (index) => makeJson(
        uuid: 'brand_$index',
        name: brandNames[index % brandNames.length],
      ),
    );
  }
}

/// Factory for creating Model test data
class ModelFactory {
  static Map<String, dynamic> makeJson({
    String? uuid,
    String? name,
    String? brandId,
  }) {
    return {
      'uuid': uuid ?? 'model_${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Camry',
      'brandId': brandId ?? 'brand_123',
    };
  }

  /// Create a list of models for a brand
  static List<Map<String, dynamic>> makeList({String? brandId, int count = 5}) {
    final modelNames = ['Camry', 'Corolla', 'RAV4', 'Highlander', 'Prius'];
    return List.generate(
      count,
      (index) => makeJson(
        uuid: 'model_$index',
        name: modelNames[index % modelNames.length],
        brandId: brandId,
      ),
    );
  }
}
