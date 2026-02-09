class PostValidator {
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a price';
    }
    final price = double.tryParse(value);
    if (price == null || price.isNaN || price < 0) {
      return 'Please enter a valid positive price';
    }
    return null;
  }

  static String? validateBrand(String? uuid) {
    if (uuid == null || uuid.isEmpty) {
      return 'Please select a brand';
    }
    return null;
  }

  static String? validateModel(String? uuid) {
    if (uuid == null || uuid.isEmpty) {
      return 'Please select a model';
    }
    return null;
  }

  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a location';
    }
    return null;
  }

  static bool canPost({
    required String? brandUuid,
    required String? modelUuid,
    required String priceText,
    required String? location,
    required bool hasMedia,
  }) {
    return validateBrand(brandUuid) == null &&
        validateModel(modelUuid) == null &&
        validatePrice(priceText) == null &&
        validateLocation(location) == null &&
        hasMedia;
  }
}
