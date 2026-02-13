import 'package:auto_tm/data/dtos/post_dto.dart';
import 'package:auto_tm/data/mappers/mapper_utils.dart';
import 'package:auto_tm/domain/models/post.dart';

class PostMapper {
  static Post fromJson(Map<String, dynamic> json) {
    return fromDto(PostDto.fromJson(json));
  }

  static Post fromDto(PostDto dto) {
    final personalInfo = dto.personalInfo;
    final region =
        personalInfo?['region']?.toString() ??
        personalInfo?['location']?.toString() ??
        '';

    // Photo handling
    String photoPath = '';
    List<String> photoPaths = [];
    if (dto.photo != null && dto.photo!.isNotEmpty) {
      // Attempt to sort photos by filename 'photo_{index}_' if possible
      var sortedPhotos = List<dynamic>.from(dto.photo!);
      
      // LOGGING RAW PHOTOS
      print('[PostMapper] Raw photos for ${dto.uuid}: ${dto.photo}');

      try {
        sortedPhotos.sort((a, b) {
          if (a is Map && b is Map) {
            String? pathA, pathB;
            if (a['path'] is String) pathA = a['path'];
            else if (a['path'] is Map) pathA = MapperUtils.pickImageVariant(a['path']);
            
            if (b['path'] is String) pathB = b['path'];
            else if (b['path'] is Map) pathB = MapperUtils.pickImageVariant(b['path']);

            // Primary Sort: Filename index (if preserved)
            if (pathA != null && pathB != null) {
              final regExp = RegExp(r'photo_(\d+)_');
              final matchA = regExp.firstMatch(pathA);
              final matchB = regExp.firstMatch(pathB);
              if (matchA != null && matchB != null) {
                final idxA = int.parse(matchA.group(1)!);
                final idxB = int.parse(matchB.group(1)!);
                return idxA.compareTo(idxB);
              }
            }

            // Secondary Sort: CreatedAt (Oldest first = First uploaded)
            // Backend returns newest first usually, so we need to reverse that.
            if (a['createdAt'] != null && b['createdAt'] != null) {
               final dateA = DateTime.tryParse(a['createdAt'].toString());
               final dateB = DateTime.tryParse(b['createdAt'].toString());
               if (dateA != null && dateB != null) {
                 return dateA.compareTo(dateB);
               }
            }

            // Tertiary Sort: ID (if available)
            if (a['id'] != null && b['id'] != null) {
               return a['id'].toString().compareTo(b['id'].toString());
            }
          }
          return 0;
        });
      } catch (e) {
        print('[PostMapper] Sort error: $e');
      }

      // LOGGING SORTED PHOTOS
      print('[PostMapper] Sorted photos: $sortedPhotos');

      final firstPhoto = sortedPhotos[0];
      if (firstPhoto is Map) {
        final pathVal = firstPhoto['path'];
        if (pathVal is String) {
          photoPath = pathVal;
        } else if (pathVal is Map) {
          photoPath = MapperUtils.pickImageVariant(pathVal);
        }
      }

      photoPaths = sortedPhotos
          .map((p) {
            if (p is Map) {
              final pathVal = p['path'];
              if (pathVal is String) return pathVal;
              if (pathVal is Map) return MapperUtils.pickImageVariant(pathVal);
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

  static String _extractBrandFromLegacy(PostDto dto) {
    if (dto.brandName != null) return dto.brandName!;
    if (dto.brandObj != null) {
      final name = dto.brandObj!['name']?.toString() ?? '';
      // Get.log('[PostMapper] Extracted brand: $name from obj');
      return name;
    }
    // If the API returns a nested object instead of a flat name
    final personal = dto.personalInfo;
    if (personal != null && personal['brand'] != null) {
      return personal['brand']['name']?.toString() ?? '';
    }
    return '';
  }

  static String _extractModelFromLegacy(PostDto dto) {
    if (dto.modelName != null) return dto.modelName!;
    if (dto.modelObj != null) {
      final name = dto.modelObj!['name']?.toString() ?? '';
      // Get.log('[PostMapper] Extracted model: $name from obj');
      return name;
    }
    final personal = dto.personalInfo;
    if (personal != null && personal['model'] != null) {
      return personal['model']['name']?.toString() ?? '';
    }
    return '';
  }
}