import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:auto_tm/services/search_service.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/screens/search_screen/model/search_model.dart';

import 'search_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
void main() {
  late SearchService service;
  late MockDio mockDio;
  late ApiClient apiClient;

  setUp(() {
    Get.reset();
    mockDio = MockDio();
    apiClient = ApiClient(dio: mockDio);
    Get.put<ApiClient>(apiClient);

    // Stub the initial _ensureIndex call which runs on Init
    when(mockDio.get(
      'brands/search',
      queryParameters: anyNamed('queryParameters'),
      options: anyNamed('options'),
      cancelToken: anyNamed('cancelToken'),
      onReceiveProgress: anyNamed('onReceiveProgress'),
      data: anyNamed('data'),
    )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: 'brands/search'),
          statusCode: 200,
          data: {},
        ));

    service = Get.put(SearchService());
  });

  tearDown(() {
    Get.reset();
  });

  group('SearchService Local Index (Fuzzy)', () {
    final mockIndex = [
      SearchModel(
          label: 'Toyota Camry',
          brandLabel: 'Toyota',
          modelLabel: 'Camry',
          brandUuid: 't1',
          modelUuid: 'c1',
          compare: 'toyota camry'),
      SearchModel(
          label: 'Toyota Corolla',
          brandLabel: 'Toyota',
          modelLabel: 'Corolla',
          brandUuid: 't1',
          modelUuid: 'c2',
          compare: 'toyota corolla'),
      SearchModel(
          label: 'BMW X5',
          brandLabel: 'BMW',
          modelLabel: 'X5',
          brandUuid: 'b1',
          modelUuid: 'x1',
          compare: 'bmw x5'),
    ];

    test('finds exact match ignoring case', () async {
      service.setIndexForTesting(mockIndex);
      final results = await service.search('toyota');
      expect(results.length, 2);
      expect(results.first.label, contains('Toyota'));
    });

    test('finds item by model only', () async {
      service.setIndexForTesting(mockIndex);
      final results = await service.search('x5');
      expect(results.first.label, 'BMW X5');
    });

    test('handles reordered tokens (smart search)', () async {
      service.setIndexForTesting(mockIndex);
      final results = await service.search('x5 bmw');
      expect(results.first.label, 'BMW X5');
    });

    test('fuzzy match handles typos', () async {
      service.setIndexForTesting(mockIndex);
      // 'toyt' -> should match Toyota
      final results = await service.search('toyt');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.brandLabel == 'Toyota'), true);
    });

    test('ranks better matches higher', () async {
      // Setup a case where multiple things match "Corolla" loosely, but one is exact
      // Actually, simple test: "Toyta Corola" -> should match Toyota Corolla
      service.setIndexForTesting(mockIndex);
      
      final results = await service.search('Toyta Corola');
      expect(results.first.label, 'Toyota Corolla');
    });
  });

  group('SearchService API Fallback', () {
    test('calls API when index is empty and not ready', () async {
      // ensure index is NOT ready (default)
      expect(service.indexReady.value, false);

      when(mockDio.get(
        'brands/search',
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'brands/search'),
            statusCode: 200,
            data: {
              'results': [
                {
                  'label': 'API Result',
                  'brand': {'label': 'A', 'uuid': '1'},
                  'model': {'label': 'B', 'uuid': '2'},
                  'compare': 'api result'
                }
              ]
            },
          ));

      final results = await service.search('query', offset: 0, limit: 10);
      
      verify(mockDio.get(
        'brands/search',
        queryParameters: argThat(containsPair('search', 'query'), named: 'queryParameters'),
      )).called(1);

      expect(results.first.label, 'API Result');
    });
  });
}
