class BrandDto {
  final String uuid;
  final String name;
  BrandDto({required this.uuid, required this.name});
  factory BrandDto.fromJson(Map<String, dynamic> json) => BrandDto(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
  Map<String, dynamic> toJson() => {'uuid': uuid, 'name': name};
}
