import 'package:get/get.dart';
import 'package:auto_tm/data/dtos/post_dto.dart' as data;
import 'package:auto_tm/data/mappers/post_mapper.dart';
import 'package:auto_tm/domain/models/post.dart' as domain;

/// Simple failure wrapper for error handling
class Failure {
  final String? message;
  Failure(this.message);
  @override
  String toString() => message ?? 'Unknown error';
}

// Aliases for compatibility
typedef PostDto = data.PostDto;

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

/// Tri-state status mapping for nullable boolean status.
enum PostStatusTri { pending, active, inactive }

extension PostDtoStatusExt on domain.Post {
  PostStatusTri get triStatus {
    if (status == null) return PostStatusTri.pending;
    return status! ? PostStatusTri.active : PostStatusTri.inactive;
  }

  String statusLabel({String? pending, String? active, String? inactive}) {
    switch (triStatus) {
      case PostStatusTri.pending:
        return pending ?? 'post_status_pending'.tr;
      case PostStatusTri.active:
        return active ?? 'post_status_active'.tr;
      case PostStatusTri.inactive:
        return inactive ?? 'post_status_declined'.tr;
    }
  }
}

extension PostLegacyExtension on domain.Post {
  static domain.Post fromJson(Map<String, dynamic> json) {
    return PostMapper.fromDto(data.PostDto.fromJson(json));
  }
}