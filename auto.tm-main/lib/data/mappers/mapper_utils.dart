class MapperUtils {
  static String pickImageVariant(Map? variantMap) {
    if (variantMap == null) return '';
    const order = ['medium', 'small', 'originalPath', 'original', 'large'];
    for (final k in order) {
      final v = variantMap[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}
