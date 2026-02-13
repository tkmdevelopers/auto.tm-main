import 'package:get/get.dart';

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
  final String region;
  final bool? exchange;
  final bool? credit;
  final String? subscription;
  final String photoPath;
  final List<String> photoPaths;
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
}

/// Tri-state status mapping for nullable boolean status.
enum PostStatusTri { pending, active, inactive }

extension PostStatusExt on Post {
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
}
