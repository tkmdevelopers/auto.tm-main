import 'dart:convert';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/screens/post_details_screen/domain/auth_token_provider.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:http/http.dart' as http;

class PostRepository {
  final AuthTokenProvider _tokenProvider;
  final http.Client _client;

  PostRepository({
    required AuthTokenProvider tokenProvider,
    http.Client? client,
  })  : _tokenProvider = tokenProvider,
        _client = client ?? http.Client();

  Future<Post> fetchPost(String uuid) async {
    final url = Uri.parse('${ApiKey.getPostDetailsKey}$uuid?model=true&brand=true&photo=true');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_tokenProvider.getAccessToken()}',
    };

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Post.fromJson(data);
    } else if (response.statusCode == 406) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        // Retry once with refreshed token
        final retryResponse = await _client.get(url, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_tokenProvider.getAccessToken()}',
        });
        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          return Post.fromJson(data);
        }
        throw RepositoryException('token_refresh_failed');
      } else {
        throw RepositoryException('token_refresh_failed');
      }
    } else {
      throw RepositoryHttpException(response.statusCode, 'http_${response.statusCode}');
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = _tokenProvider.getRefreshToken();
    if (refreshToken == null) return false;
    final response = await _client.get(
      Uri.parse(ApiKey.refreshTokenKey),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['accessToken'];
      if (newAccessToken != null) {
        await _tokenProvider.setAccessToken(newAccessToken);
        return true;
      }
    }
    return false;
  }
}

class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);
  @override
  String toString() => 'RepositoryException($message)';
}

class RepositoryHttpException extends RepositoryException {
  final int statusCode;
  RepositoryHttpException(this.statusCode, String message) : super(message);
  @override
  String toString() => 'RepositoryHttpException($statusCode, $message)';
}
