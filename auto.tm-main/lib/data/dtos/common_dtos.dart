/// Photo data transfer object
class PhotoDto {
  final String uuid;
  final String? originalPath;
  final Map<String, String>? path;

  PhotoDto({required this.uuid, this.originalPath, this.path});

  factory PhotoDto.fromJson(Map<String, dynamic> json) {
    Map<String, String>? variants;
    final pathObj = json['path'];
    if (pathObj is Map) {
      variants = pathObj.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return PhotoDto(
      uuid: json['uuid']?.toString() ?? '',
      originalPath: json['originalPath']?.toString(),
      path: variants,
    );
  }
}

/// Brand data transfer object
class BrandDto {
  final String uuid;
  final String name;
  final PhotoDto? photo;

  BrandDto({required this.uuid, required this.name, this.photo});

  factory BrandDto.fromJson(Map<String, dynamic> json) => BrandDto(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    photo: json['photo'] != null ? PhotoDto.fromJson(json['photo']) : null,
  );
}

/// Model data transfer object
class ModelDto {
  final String uuid;
  final String name;

  ModelDto({required this.uuid, required this.name});

  factory ModelDto.fromJson(Map<String, dynamic> json) => ModelDto(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
}
