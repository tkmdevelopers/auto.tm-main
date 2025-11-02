import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_tm/utils/key.dart';
import 'repository_exceptions.dart';

abstract class IPostRepository {
  Future<String?> createPost(Map<String, dynamic> body, {String? token});
  Future<List<Map<String, dynamic>>> fetchMyPosts({String? token});
}

class PostRepository implements IPostRepository {
  final http.Client _client;
  PostRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<String?> createPost(Map<String, dynamic> body, {String? token}) async {
    final resp = await _client.post(
      Uri.parse(ApiKey.postPostsKey),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data['uuid']?.toString();
    } else if (resp.statusCode == 406) {
      throw AuthExpiredException();
    }
    throw HttpException('createPost status ${resp.statusCode}');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyPosts({String? token}) async {
    final resp = await _client
        .get(
          Uri.parse(ApiKey.getMyPostsKey),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      List<dynamic> rawPosts;
      if (data is List) {
        rawPosts = data;
      } else if (data is Map && data['data'] is List) {
        rawPosts = data['data'] as List;
      } else {
        rawPosts = [];
      }
      return rawPosts.whereType<Map<String, dynamic>>().toList();
    } else if (resp.statusCode == 406) {
      throw AuthExpiredException();
    }
    throw HttpException('fetchMyPosts status ${resp.statusCode}');
  }
}
