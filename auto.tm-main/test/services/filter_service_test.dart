import 'package:auto_tm/domain/models/post_filter.dart';
import 'package:auto_tm/services/filter_service.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'filter_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
void main() {
  late MockDio mockDio;
  late ApiClient apiClient;
  late FilterService service;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    mockDio = MockDio();

    when(mockDio.interceptors).thenReturn(Interceptors());
    when(mockDio.options).thenReturn(BaseOptions());

    apiClient = ApiClient(dio: mockDio);
    Get.put<ApiClient>(apiClient);

    service = FilterService();
    Get.put<FilterService>(service);
  });

  tearDown(() {
    Get.reset();
  });

  group('FilterService', () {
    test('searchPosts success', () async {
      when(
        mockDio.get('posts', queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'posts'),
          statusCode: 200,
          data: [
            {'uuid': '123', 'price': 100},
          ],
        ),
      );

      final result = await service.searchPosts(filters: PostFilter());
      expect(result.length, 1);
      expect(result.first.uuid, '123');
    });

    test('searchPosts handles string data', () async {
      when(
        mockDio.get('posts', queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'posts'),
          statusCode: 200,
          data: '[{"uuid": "123", "price": 100}]',
        ),
      );

      final result = await service.searchPosts(filters: PostFilter());
      expect(result.length, 1);
    });

    test('searchPosts error returns empty list', () async {
      when(
        mockDio.get('posts', queryParameters: anyNamed('queryParameters')),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final result = await service.searchPosts(filters: PostFilter());
      expect(result, isEmpty);
    });
  });
}
