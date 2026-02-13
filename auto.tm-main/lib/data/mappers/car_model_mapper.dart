import 'package:auto_tm/data/dtos/common_dtos.dart';
import 'package:auto_tm/domain/models/car_model.dart';

class CarModelMapper {
  static CarModel fromDto(ModelDto dto) {
    return CarModel(uuid: dto.uuid, name: dto.name);
  }

  static CarModel fromJson(Map<String, dynamic> json) {
    return fromDto(ModelDto.fromJson(json));
  }
}
