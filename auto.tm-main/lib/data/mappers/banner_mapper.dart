import 'package:auto_tm/domain/models/banner.dart';

class BannerMapper {
  static Banner fromJson(Map<String, dynamic> json) {
    return Banner(
      uuid: json['uuid']?.toString() ?? '',
      imagePath: json['photo']?['path']?['medium']?.toString() ?? '',
    );
  }
}
