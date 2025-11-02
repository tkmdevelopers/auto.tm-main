import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_tm/utils/key.dart';
import '../model/model_dto.dart';
import 'repository_exceptions.dart';

abstract class IModelRepository {
  Future<List<ModelDto>> fetchModels(String brandUuid, {String? token});
}

class ModelRepository implements IModelRepository {
  final http.Client _client;
  ModelRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<ModelDto>> fetchModels(String brandUuid, {String? token}) async {
    if (brandUuid.isEmpty) return [];
    final uri = Uri.parse('${ApiKey.getModelsKey}?filter=$brandUuid');
    final resp = await _client
        .get(
          uri,
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
          .map((m) => ModelDto.fromJson(Map<String, dynamic>.from(m)))
          .where((m) => m.uuid.isNotEmpty && m.name.isNotEmpty)
          .toList();
    } else if (resp.statusCode == 406) {
      throw AuthExpiredException();
    } else {
      throw HttpException('Status ${resp.statusCode}');
    }
  }
}
