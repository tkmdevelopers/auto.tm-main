import 'dart:async';

import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/services/brand_model_service.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'brand_model_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<GetStorage>(),
])
void main() {
  late MockDio mockDio;
  late MockGetStorage mockStorage;
  late ApiClient apiClient;
  late BrandModelService service;

  setUp(() {
    Get.reset();
    Get.testMode = true;

    mockDio = MockDio();
    mockStorage = MockGetStorage();

    when(mockDio.interceptors).thenReturn(Interceptors());
    when(mockDio.options).thenReturn(BaseOptions());

    // Default storage responses
    when(mockStorage.read(any)).thenReturn(null);
    when(mockStorage.write(any, any)).thenAnswer((_) async {});
    when(mockStorage.getKeys()).thenReturn([]);

    apiClient = ApiClient(dio: mockDio);
    service = BrandModelService.withStorage(apiClient, mockStorage);

    Get.put<ApiClient>(apiClient);
    Get.put<BrandModelService>(service);
  });

  tearDown(() {
    Get.reset();
  });

  group('BrandModelService - Brands Fetching', () {
    test('fetchBrands should fetch from API and cache response', () async {
      final mockResponse = {
        'data': [
          {'uuid': 'b1', 'name': 'Toyota'},
          {'uuid': 'b2', 'name': 'Honda'},
        ]
      };

      when(mockDio.get('brands')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'brands'),
          statusCode: 200,
          data: mockResponse,
        ),
      );

      await service.fetchBrands();

      expect(service.brands.length, 2);
      expect(service.brands[0].name, 'Toyota');
      expect(service.brands[1].name, 'Honda');
      expect(service.isLoadingBrands.value, false);
      expect(service.brandsFromCache.value, false);

      // Verify cache write was called
      verify(mockStorage.write(any, any)).called(greaterThan(0));
    });

    test('fetchBrands should handle timeout with cache fallback', () async {
      when(mockStorage.read('BRAND_CACHE_V1')).thenReturn({
        'storedAt': DateTime.now().toIso8601String(),
        'items': [
          {'uuid': 'b1', 'name': 'Cached Brand'}
        ]
      });

      when(mockDio.get('brands')).thenAnswer(
        (_) async => throw TimeoutException('Request timeout'),
      );

      await service.fetchBrands();

      // Cache should be hydrated during fallback
      expect(service.brandsFromCache.value, true);
      expect(service.isLoadingBrands.value, false);
    });

    test('fetchBrands should skip if already loaded and not forcing refresh',
        () async {
      service.brands.assignAll([
        BrandDto(uuid: 'b1', name: 'Existing Brand'),
      ]);

      await service.fetchBrands();

      // Should not call API
      verifyNever(mockDio.get(any));
      expect(service.brands.length, 1);
    });

    test('fetchBrands should force refresh when forceRefresh=true', () async {
      service.brands.assignAll([
        BrandDto(uuid: 'b1', name: 'Old Brand'),
      ]);

      final mockResponse = {
        'data': [
          {'uuid': 'b1', 'name': 'New Brand'}
        ]
      };

      when(mockDio.get('brands')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'brands'),
          statusCode: 200,
          data: mockResponse,
        ),
      );

      await service.fetchBrands(forceRefresh: true);

      expect(service.brands[0].name, 'New Brand');
      verify(mockDio.get('brands')).called(1);
    });

    test('fetchBrands should handle API error gracefully', () async {
      when(mockDio.get('brands')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'brands'),
          statusCode: 500,
          data: null,
        ),
      );

      await service.fetchBrands();

      expect(service.isLoadingBrands.value, false);
      // Should fallback to empty or cached list
    });
  });

  group('BrandModelService - Models Fetching', () {
    test('fetchModels should fetch models for given brand', () async {
      final mockResponse = {
        'data': [
          {'uuid': 'm1', 'name': 'Camry'},
          {'uuid': 'm2', 'name': 'Corolla'},
        ]
      };

      when(mockDio.get('models', queryParameters: {'filter': 'b1'}))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'models'),
          statusCode: 200,
          data: mockResponse,
        ),
      );

      await service.fetchModels('b1');

      expect(service.models.length, 2);
      expect(service.models[0].name, 'Camry');
      expect(service.models[1].name, 'Corolla');
      expect(service.isLoadingModels.value, false);
      expect(service.modelsFromCache.value, false);
    });

    test('fetchModels should skip if brandUuid is empty', () async {
      await service.fetchModels('');

      verifyNever(mockDio.get(any, queryParameters: anyNamed('queryParameters')));
      expect(service.models.isEmpty, true);
    });

    test('fetchModels should handle timeout with cache fallback', () async {
      when(mockStorage.read('MODEL_CACHE_V1')).thenReturn({
        'b1': {
          'storedAt': DateTime.now().toIso8601String(),
          'items': [
            {'uuid': 'm1', 'name': 'Cached Model'}
          ]
        }
      });

      when(mockDio.get('models', queryParameters: {'filter': 'b1'}))
          .thenAnswer(
        (_) async => throw TimeoutException('Request timeout'),
      );

      await service.fetchModels('b1');

      // Cache should be hydrated during fallback
      expect(service.modelsFromCache.value, true);
    });

    test('fetchModels with showLoading=false should not set loading state',
        () async {
      when(mockDio.get('models', queryParameters: {'filter': 'b1'}))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'models'),
          statusCode: 200,
          data: {
            'data': [
              {'uuid': 'm1', 'name': 'Model1'}
            ]
          },
        ),
      );

      service.isLoadingModels.value = false;

      await service.fetchModels('b1', showLoading: false);

      expect(service.isLoadingModels.value, false);
      expect(service.models.length, 1);
    });
  });

  group('BrandModelService - Search Filtering', () {
    test('filteredBrands should filter by search query', () {
      service.brands.assignAll([
        BrandDto(uuid: 'b1', name: 'Toyota'),
        BrandDto(uuid: 'b2', name: 'Honda'),
        BrandDto(uuid: 'b3', name: 'Ford'),
      ]);

      service.brandSearchQuery.value = 'toy';

      final filtered = service.filteredBrands;

      expect(filtered.length, 1);
      expect(filtered[0].name, 'Toyota');
    });

    test('filteredBrands should return all brands when query is empty', () {
      service.brands.assignAll([
        BrandDto(uuid: 'b1', name: 'Toyota'),
        BrandDto(uuid: 'b2', name: 'Honda'),
      ]);

      service.brandSearchQuery.value = '';

      final filtered = service.filteredBrands;

      expect(filtered.length, 2);
    });

    test('filteredBrands should be case-insensitive', () {
      service.brands.assignAll([
        BrandDto(uuid: 'b1', name: 'Toyota'),
        BrandDto(uuid: 'b2', name: 'honda'),
      ]);

      service.brandSearchQuery.value = 'HONDA';

      final filtered = service.filteredBrands;

      expect(filtered.length, 1);
      expect(filtered[0].name, 'honda');
    });

    test('filteredModels should filter by search query', () {
      service.models.assignAll([
        ModelDto(uuid: 'm1', name: 'Camry'),
        ModelDto(uuid: 'm2', name: 'Corolla'),
        ModelDto(uuid: 'm3', name: 'Civic'),
      ]);

      service.modelSearchQuery.value = 'cam';

      final filtered = service.filteredModels;

      expect(filtered.length, 1);
      expect(filtered[0].name, 'Camry');
    });

    test('filteredModels should return all models when query is empty', () {
      service.models.assignAll([
        ModelDto(uuid: 'm1', name: 'Camry'),
        ModelDto(uuid: 'm2', name: 'Civic'),
      ]);

      service.modelSearchQuery.value = '';

      final filtered = service.filteredModels;

      expect(filtered.length, 2);
    });
  });

  group('BrandModelService - Name Resolution', () {
    test('resolveBrandName should return name for non-UUID string', () {
      final result = service.resolveBrandName('Toyota');

      expect(result, 'Toyota');
    });

    test('resolveBrandName should return input if not UUID-like', () {
      final result = service.resolveBrandName('Toyota');

      expect(result, 'Toyota');
    });

    test('resolveBrandName should return UUID if not found in cache', () {
      final result = service.resolveBrandName('unknown-uuid-123');

      expect(result, 'unknown-uuid-123');
    });

    test('resolveModelName should return name for non-UUID string', () {
      final result = service.resolveModelName('Camry');

      expect(result, 'Camry');
    });

    test('resolveModelName should return input if not UUID-like', () {
      final result = service.resolveModelName('Camry');

      expect(result, 'Camry');
    });

    test('resolveModelName should return empty string for empty input', () {
      expect(service.resolveBrandName(''), '');
      expect(service.resolveModelName(''), '');
    });
  });

  group('BrandModelService - Cache TTL', () {
    test('should use cached brands if within TTL', () async {
      when(mockStorage.read('BRAND_CACHE_V1')).thenReturn({
        'storedAt': DateTime.now().toIso8601String(),
        'items': [
          {'uuid': 'b1', 'name': 'Cached Brand'}
        ]
      });

      service.brandsFromCache.value = true;
      service.brands.assignAll([
        BrandDto(uuid: 'b1', name: 'Cached Brand'),
      ]);

      await service.fetchBrands();

      // Should not call API if brands already loaded and cache is fresh
      verifyNever(mockDio.get('brands'));
      expect(service.brands[0].name, 'Cached Brand');
    });

    test('should refetch brands if forcing refresh', () async {
      final mockResponse = {
        'data': [
          {'uuid': 'b1', 'name': 'Fresh Brand'}
        ]
      };

      when(mockDio.get('brands')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'brands'),
          statusCode: 200,
          data: mockResponse,
        ),
      );

      service.brandsFromCache.value = true;
      service.brands.assignAll([
        BrandDto(uuid: 'b1', name: 'Old Brand'),
      ]);

      await service.fetchBrands(forceRefresh: true);

      verify(mockDio.get('brands')).called(1);
      expect(service.brands[0].name, 'Fresh Brand');
    });
  });
}
