import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:auto_tm/screens/post_screen/repository/brand_repository.dart';
import 'package:auto_tm/screens/post_screen/model/brand_dto.dart';
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

  test('fetchBrands returns parsed list', () async {
    final brandsJson = [
      {'uuid': '1', 'name': 'BrandA'},
      {'uuid': '2', 'name': 'BrandB'},
    ];
    final client = FakeClient({
      Uri.parse('https://your-api-base-url.com/api/v1/brands'): http.Response(
        jsonEncode(brandsJson),
        200,
      ),
    });
    final repo = BrandRepository(client: client);
    final list = await repo.fetchBrands();
    expect(list.length, 2);
    expect(list.first, isA<BrandDto>());
    expect(list.first.name, 'BrandA');
  });

  test('fetchBrands throws AuthExpiredException on 406', () async {
    final client = FakeClient({
      Uri.parse('https://your-api-base-url.com/api/v1/brands'): http.Response(
        '[]',
        406,
      ),
    });
    final repo = BrandRepository(client: client);
    expect(repo.fetchBrands(), throwsA(isA<AuthExpiredException>()));
  });
}
