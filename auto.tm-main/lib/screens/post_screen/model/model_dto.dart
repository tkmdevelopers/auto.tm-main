class ModelDto {
  final String uuid;
  final String name;
  ModelDto({required this.uuid, required this.name});
  factory ModelDto.fromJson(Map<String, dynamic> json) => ModelDto(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
  Map<String, dynamic> toJson() => {'uuid': uuid, 'name': name};
}
