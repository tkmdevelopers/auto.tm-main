import 'package:auto_tm/data/dtos/post_dto.dart';
import 'package:auto_tm/domain/models/post.dart';

class PostMapper {
  static Post fromDto(PostDto dto) {
    final personalInfo = dto.personalInfo;
    final region = personalInfo?['region']?.toString() ?? personalInfo?['location']?.toString() ?? '';
    
    // Photo handling
    String photoPath = '';
    List<String> photoPaths = [];
    if (dto.photo != null && dto.photo!.isNotEmpty) {
      final firstPhoto = dto.photo![0];
      if (firstPhoto is Map) {
        photoPath = _pickImageVariant(firstPhoto['path'] as Map? ?? {});
      }
      
      photoPaths = dto.photo!
          .map((p) {
            if (p is Map) {
              return _pickImageVariant(p['path'] as Map? ?? {});
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Video handling
    String? videoUrl;
    if (dto.video != null) {
      videoUrl = (dto.video!['publicUrl'] ?? dto.video!['url'])?.toString();
    }

    // File handling
    FileData? fileData;
    if (dto.file != null) {
      fileData = FileData(
        uuid: dto.file!['uuid']?.toString() ?? '',
        path: dto.file!['path']?.toString() ?? '',
        postId: dto.file!['postId']?.toString() ?? '',
        createdAt: dto.file!['createdAt']?.toString() ?? '',
        updatedAt: dto.file!['updatedAt']?.toString() ?? '',
      );
    }

    // Subscription small icon
    String? subIcon;
    if (dto.subscription != null) {
      subIcon = dto.subscription!['photo']?['path']?['small'] as String?;
    }

    return Post(
      uuid: dto.uuid,
      model: dto.modelName ?? _extractModelFromLegacy(dto),
      brand: dto.brandName ?? _extractBrandFromLegacy(dto),
      price: (dto.price ?? 0).toDouble(),
      year: (dto.year ?? 0).toDouble(),
      milleage: (dto.milleage ?? 0).toDouble(),
      engineType: dto.engineType ?? '',
      enginePower: (dto.enginePower ?? 0).toDouble(),
      description: dto.description ?? '',
      location: dto.location ?? '',
      transmission: dto.transmission ?? '',
      vinCode: dto.vin ?? '',
      condition: dto.condition ?? '',
      currency: dto.currency ?? '',
      status: dto.status,
      phoneNumber: personalInfo?['phone']?.toString() ?? '',
      photoPath: photoPath,
      photoPaths: photoPaths,
      subscription: subIcon,
      video: videoUrl,
      createdAt: dto.createdAt ?? '',
      region: region,
      exchange: dto.exchange,
      credit: dto.credit,
      file: fileData,
    );
  }

  static String _pickImageVariant(Map variantMap) {
    const order = ['medium', 'small', 'originalPath', 'original', 'large'];
    for (final k in order) {
      final v = variantMap[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static String _extractBrandFromLegacy(PostDto dto) {
    if (dto.brandName != null) return dto.brandName!;
    // If the API returns a nested object instead of a flat name
    final personal = dto.personalInfo;
    if (personal != null && personal['brand'] != null) {
      return personal['brand']['name']?.toString() ?? '';
    }
    return '';
  }

  static String _extractModelFromLegacy(PostDto dto) {
    if (dto.modelName != null) return dto.modelName!;
    final personal = dto.personalInfo;
    if (personal != null && personal['model'] != null) {
      return personal['model']['name']?.toString() ?? '';
    }
    return '';
  }
}