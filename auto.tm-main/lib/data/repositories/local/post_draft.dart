import 'dart:convert';

/// Represents a locally stored draft for a post that hasn't yet been published.
class PostDraft {
  final String id; // locally generated id
  final DateTime createdAt;
  final DateTime updatedAt;

  // Core fields
  final String brandUuid;
  final String modelUuid;
  final String brandName;
  final String modelName;
  final String condition;
  final int? year; // may be null until selected
  final double? price;
  final String currency;
  final String location;
  final bool credit;
  final bool exchange;
  final String transmission;
  final String engineType;
  final double? enginePower;
  final double? milleage;
  final String vin;
  final String description;
  final String phone; // normalized 8-digit local number
  final String title; // user provided or auto-generated display title
  final bool phoneVerified; // whether phone was verified at save time

  // Media (schema v2+)
  final List<String> imageBase64; // base64 encoded JPEGs (preview quality)
  final String? originalVideoPath; // Original selected video file path
  final String? compressedVideoPath; // Compressed video file path if created
  final int? originalVideoBytes;
  final int? compressedVideoBytes;
  final bool
  usedCompressed; // Whether compressed variant was selected for upload
  final String?
  videoThumbnailBase64; // Cached thumbnail (small JPEG) to avoid regenerating
  final int schemaVersion; // For future migrations
  @Deprecated('Use originalVideoPath instead')
  final String? videoPath; // Backward compatibility with v1

  PostDraft({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.brandUuid,
    required this.modelUuid,
    required this.brandName,
    required this.modelName,
    required this.condition,
    required this.year,
    required this.price,
    required this.currency,
    required this.location,
    required this.credit,
    required this.exchange,
    required this.transmission,
    required this.engineType,
    required this.enginePower,
    required this.milleage,
    required this.vin,
    required this.description,
    required this.phone,
    required this.title,
    required this.phoneVerified,
    required this.imageBase64,
    required this.originalVideoPath,
    required this.compressedVideoPath,
    required this.originalVideoBytes,
    required this.compressedVideoBytes,
    required this.usedCompressed,
    required this.videoThumbnailBase64,
    required this.schemaVersion,
    this.videoPath,
  });

  PostDraft copyWith({
    DateTime? updatedAt,
    String? brandUuid,
    String? modelUuid,
    String? brandName,
    String? modelName,
    String? condition,
    int? year,
    double? price,
    String? currency,
    String? location,
    bool? credit,
    bool? exchange,
    String? transmission,
    String? engineType,
    double? enginePower,
    double? milleage,
    String? vin,
    String? description,
    String? phone,
    String? title,
    bool? phoneVerified,
    List<String>? imageBase64,
    String? originalVideoPath,
    String? compressedVideoPath,
    int? originalVideoBytes,
    int? compressedVideoBytes,
    bool? usedCompressed,
    String? videoThumbnailBase64,
    int? schemaVersion,
    String? videoPath,
  }) => PostDraft(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    brandUuid: brandUuid ?? this.brandUuid,
    modelUuid: modelUuid ?? this.modelUuid,
    brandName: brandName ?? this.brandName,
    modelName: modelName ?? this.modelName,
    condition: condition ?? this.condition,
    year: year ?? this.year,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    location: location ?? this.location,
    credit: credit ?? this.credit,
    exchange: exchange ?? this.exchange,
    transmission: transmission ?? this.transmission,
    engineType: engineType ?? this.engineType,
    enginePower: enginePower ?? this.enginePower,
    milleage: milleage ?? this.milleage,
    vin: vin ?? this.vin,
    description: description ?? this.description,
    phone: phone ?? this.phone,
    title: title ?? this.title,
    phoneVerified: phoneVerified ?? this.phoneVerified,
    imageBase64: imageBase64 ?? this.imageBase64,
    originalVideoPath: originalVideoPath ?? this.originalVideoPath,
    compressedVideoPath: compressedVideoPath ?? this.compressedVideoPath,
    originalVideoBytes: originalVideoBytes ?? this.originalVideoBytes,
    compressedVideoBytes: compressedVideoBytes ?? this.compressedVideoBytes,
    usedCompressed: usedCompressed ?? this.usedCompressed,
    videoThumbnailBase64: videoThumbnailBase64 ?? this.videoThumbnailBase64,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    videoPath: videoPath ?? this.videoPath,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'brandUuid': brandUuid,
    'modelUuid': modelUuid,
    'brandName': brandName,
    'modelName': modelName,
    'condition': condition,
    'year': year,
    'price': price,
    'currency': currency,
    'location': location,
    'credit': credit,
    'exchange': exchange,
    'transmission': transmission,
    'engineType': engineType,
    'enginePower': enginePower,
    'milleage': milleage,
    'vin': vin,
    'description': description,
    'phone': phone,
    'title': title,
    'phoneVerified': phoneVerified,
    'imageBase64': imageBase64,
    'originalVideoPath': originalVideoPath,
    'compressedVideoPath': compressedVideoPath,
    'originalVideoBytes': originalVideoBytes,
    'compressedVideoBytes': compressedVideoBytes,
    'usedCompressed': usedCompressed,
    'videoThumbnailBase64': videoThumbnailBase64,
    'schemaVersion': schemaVersion,
    'videoPath': videoPath, // legacy
  };

  factory PostDraft.fromMap(Map<String, dynamic> map) {
    final int schemaVersion = (map['schemaVersion'] is int)
        ? map['schemaVersion'] as int
        : 1; // default legacy
    // Backward compatibility: legacy videoPath becomes originalVideoPath
    final legacyVideoPath = map['videoPath'];
    return PostDraft(
      id: map['id'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      brandUuid: map['brandUuid'] ?? '',
      modelUuid: map['modelUuid'] ?? '',
      brandName: map['brandName'] ?? '',
      modelName: map['modelName'] ?? '',
      condition: map['condition'] ?? '',
      year: map['year'],
      price: (map['price'] is num) ? (map['price'] as num?)?.toDouble() : null,
      currency: map['currency'] ?? 'TMT',
      location: map['location'] ?? '',
      credit: map['credit'] ?? false,
      exchange: map['exchange'] ?? false,
      transmission: map['transmission'] ?? '',
      engineType: map['engineType'] ?? '',
      enginePower: (map['enginePower'] is num)
          ? (map['enginePower'] as num?)?.toDouble()
          : null,
      milleage: (map['milleage'] is num)
          ? (map['milleage'] as num?)?.toDouble()
          : null,
      vin: map['vin'] ?? '',
      description: map['description'] ?? '',
      phone: map['phone'] ?? '',
      title: map['title'] ?? '',
      phoneVerified: map['phoneVerified'] ?? false,
      imageBase64: (map['imageBase64'] as List?)?.cast<String>() ?? <String>[],
      originalVideoPath: map['originalVideoPath'] ?? legacyVideoPath,
      compressedVideoPath: map['compressedVideoPath'],
      originalVideoBytes: (map['originalVideoBytes'] is num)
          ? (map['originalVideoBytes'] as num).toInt()
          : null,
      compressedVideoBytes: (map['compressedVideoBytes'] is num)
          ? (map['compressedVideoBytes'] as num).toInt()
          : null,
      usedCompressed: map['usedCompressed'] ?? false,
      videoThumbnailBase64: map['videoThumbnailBase64'],
      schemaVersion: schemaVersion,
      videoPath: legacyVideoPath,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory PostDraft.fromJson(String source) =>
      PostDraft.fromMap(jsonDecode(source));
}
