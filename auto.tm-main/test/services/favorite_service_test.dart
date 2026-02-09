import 'package:auto_tm/services/favorite_service.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'favorite_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
])
void main() {
  late MockDio mockDio;
  late ApiClient apiClient;
  late FavoriteService service;

  setUp(() {
    Get.reset();
    Get.testMode = true;

    mockDio = MockDio();
    
    // Setup ApiClient with mock Dio
    apiClient = ApiClient(dio: mockDio);
    Get.put<ApiClient>(apiClient);

    // Setup Service
    service = FavoriteService();
    Get.put<FavoriteService>(service);
  });

  tearDown(() {
    Get.reset();
  });

  group('FavoriteService', () {
    test('fetchFavoritePosts returns list on 200', () async {
      when(mockDio.post(
        'posts/list',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: 'posts/list'),
        statusCode: 200,
        data: [
          {'uuid': '123', 'price': 1000},
          {'uuid': '456', 'price': 2000},
        ],
      ));

      final result = await service.fetchFavoritePosts(['123', '456']);
      
      expect(result, hasLength(2));
      expect(result[0].uuid, '123');
      expect(result[1].uuid, '456');
    });

    test('fetchFavoritePosts returns empty list on error', () async {
      when(mockDio.post(any, data: anyNamed('data')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final result = await service.fetchFavoritePosts(['123']);
      expect(result, isEmpty);
    });

    test('subscribeToBrand returns true on 200/201', () async {
      when(mockDio.post(
        'brands/subscribe',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: 'brands/subscribe'),
        statusCode: 200,
      ));

      final result = await service.subscribeToBrand('brand-uuid');
      expect(result, isTrue);
    });

    test('subscribeToBrand returns false on error', () async {
      when(mockDio.post(any, data: anyNamed('data')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final result = await service.subscribeToBrand('brand-uuid');
      expect(result, isFalse);
    });
    
    test('unsubscribeFromBrand returns true on 200', () async {
      when(mockDio.post(
        'brands/unsubscribe',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: 'brands/unsubscribe'),
        statusCode: 200,
      ));

      final result = await service.unsubscribeFromBrand('brand-uuid');
      expect(result, isTrue);
    });

    test('fetchSubscribedBrands returns list on 200', () async {
      when(mockDio.post(
        'brands/list',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: 'brands/list'),
        statusCode: 200,
        data: [
          {'uuid': 'b1', 'name': 'Toyota', 'posts': []},
        ],
      ));

      final result = await service.fetchSubscribedBrands(['b1']);
      expect(result, hasLength(1));
      expect(result[0]['name'], 'Toyota');
    });
  });
}
