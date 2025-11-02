import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_tm/utils/key.dart';
import '../model/brand_dto.dart';
import 'repository_exceptions.dart';

abstract class IBrandRepository {
  Future<List<BrandDto>> fetchBrands({String? token});
}

class BrandRepository implements IBrandRepository {
  final http.Client _client;
  BrandRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<BrandDto>> fetchBrands({String? token}) async {
    final resp = await _client
        .get(
          Uri.parse(ApiKey.getBrandsKey),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      final dynamic listCandidate = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] is List)
          ? decoded['data']
          : [];
      if (listCandidate is! List) return [];
      return listCandidate
          .whereType<Map>()
          .map((m) => BrandDto.fromJson(Map<String, dynamic>.from(m)))
          .where((b) => b.uuid.isNotEmpty && b.name.isNotEmpty)
          .toList();
    } else if (resp.statusCode == 406) {
      throw AuthExpiredException();
    } else {
      throw HttpException('Status ${resp.statusCode}');
    }
  }
}
