import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:auto_tm/screens/post_screen/repository/model_repository.dart';
import 'package:auto_tm/screens/post_screen/model/model_dto.dart';
import 'package:auto_tm/screens/post_screen/repository/repository_exceptions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FakeClient extends http.BaseClient {
  final Map<Uri, http.Response> responses;
  FakeClient(this.responses);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = responses[request.url];
    if (response == null) {
      return http.StreamedResponse(Stream.value([]), 404);
    }
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  setUpAll(() async {
    // Initialize dotenv with test values
    dotenv.testLoad(mergeWith: {'API_BASE': 'https://your-api-base-url.com/'});
  });

  test('fetchModels returns filtered list', () async {
    final modelsJson = [
      {'uuid': 'm1', 'name': 'Model X'},
      {'uuid': 'm2', 'name': 'Model Y'},
    ];
    final client = FakeClient({
      Uri.parse('https://your-api-base-url.com/api/v1/models?filter=brand-123'):
          http.Response(jsonEncode(modelsJson), 200),
    });
    final repo = ModelRepository(client: client);
    final list = await repo.fetchModels('brand-123');
    expect(list.length, 2);
    expect(list.first, isA<ModelDto>());
    expect(list.first.name, 'Model X');
  });

  test('fetchModels throws AuthExpiredException on 406', () async {
    final client = FakeClient({
      Uri.parse('https://your-api-base-url.com/api/v1/models?filter=brand-123'):
          http.Response('[]', 406),
    });
    final repo = ModelRepository(client: client);
    expect(repo.fetchModels('brand-123'), throwsA(isA<AuthExpiredException>()));
  });

  test('fetchModels throws HttpException on non-200/406 status', () async {
    final client = FakeClient({
      Uri.parse('https://your-api-base-url.com/api/v1/models?filter=brand-123'):
          http.Response('Server error', 500),
    });
    final repo = ModelRepository(client: client);
    expect(repo.fetchModels('brand-123'), throwsA(isA<HttpException>()));
  });
}
