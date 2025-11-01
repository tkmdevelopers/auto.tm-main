class Post {
  final String uuid;
  final String model;
  final String brand;
  final double year;
  final double milleage;
  final String engineType;
  final double enginePower;
  final String transmission;
  final String condition;
  final String vinCode;
  final double price;
  final String currency;
  final String description;
  final String location;
  final String phoneNumber;
  final String createdAt;
  final bool? status;
  // Region (personalInfo.region or fallback to personalInfo.location). 'Local' for local posts.
  final String region;
  // Whether seller allows exchange (barter)
  final bool? exchange;
  // Whether seller allows credit / financing
  final bool? credit;

  final String? subscription;
  final String photoPath;
  final List<String> photoPaths;
  // final List<Video>? videos;
  final String? video;
  final FileData? file;

  Post({
    required this.uuid,
    required this.model,
    required this.brand,
    required this.year,
    required this.price,
    required this.milleage,
    required this.condition,
    required this.currency,
    required this.description,
    required this.location,
    required this.enginePower,
    required this.engineType,
    required this.transmission,
    required this.vinCode,
    required this.phoneNumber,
    required this.region,
    this.exchange,
    this.credit,
    this.subscription,
    this.status,
    required this.photoPath,
    required this.photoPaths,
    this.video,
    this.file,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // final small = json['subscription']?['photo']?['originalPath'] as String?;
    final small = json['subscription']?['photo']?['path']?['small'] as String?;
    final personalInfo = json['personalInfo'] as Map<String, dynamic>?;
    final region =
        personalInfo?['region']?.toString() ??
        personalInfo?['location']?.toString() ??
        '';
    return Post(
      uuid: json['uuid'] ?? '',
      model: json['model']?['name'] ?? '',
      brand: json['brand']?['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      year: (json['year'] ?? 0).toDouble(),
      milleage: (json['milleage'] ?? 0).toDouble(),
      engineType: json['engineType'] ?? '',
      enginePower: (json['enginePower'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      transmission: json['transmission'] ?? '',
      vinCode: json['vin'] ?? '',
      condition: json['condition'] ?? '',
      currency: json['currency'] ?? '',
      status: json['status'] as bool?,
      // phoneNumber: json['personalInfo']!= null? json['personalInfo']['phone']:'',
      phoneNumber: json['personalInfo']?['phone'] ?? '',
      // subscription: json['subscription'] != null
      //     ? json['subscription']['photo']['small']
      //     : null,
      photoPath: (json['photo'] != null && json['photo'].isNotEmpty)
          ? (json['photo'][0]['originalPath'] ??
                    json['photo'][0]['path']['large'])
                .toString()
                .replaceAll('\\', '/')
          : '',
      photoPaths: (json['photo'] != null && json['photo'].isNotEmpty)
          ? (json['photo'] as List)
                .map(
                  (photo) => (photo['originalPath'] ?? photo['path']['large'])
                      .toString()
                      .replaceAll('\\', '/'),
                )
                .toList()
          : [],
      subscription: small,
      video: json['video'] != null
          ? ((json['video']['publicUrl'] ??
                        (json['video']['url'] != null
                            ? (json['video']['url'] as String)
                            : ''))
                    as String)
                .replaceAll('\\', '/')
          : '',
      createdAt: json['createdAt'] ?? '',
      region: region,
      exchange: json['exchange'] as bool?,
      credit: json['credit'] as bool?,
      // file: json['file'],
      file: json['file'] != null ? FileData.fromJson(json['file']) : null,
    );
  }

  toJson() {}
}

class Video {
  final int? id;
  final List<String>? url;
  final int? partNumber;
  final String? postId;
  final String? createdAt; // Изменил на String? для соответствия
  final String? updatedAt; // Изменил на String? для соответствия

  Video({
    this.id,
    this.url,
    this.partNumber,
    this.postId,
    this.createdAt,
    this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as int?,
      url: (json['url'] as List<dynamic>?)?.cast<String>(),
      partNumber: json['partNumber'] as int?,
      postId: json['postId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'partNumber': partNumber,
      'postId': postId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class FileData {
  final String uuid;
  final String path;
  final String postId;
  final String createdAt;
  final String updatedAt;

  FileData({
    required this.uuid,
    required this.path,
    required this.postId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(
      uuid: json['uuid'] ?? '',
      path: json['path'] ?? '',
      postId: json['postId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
