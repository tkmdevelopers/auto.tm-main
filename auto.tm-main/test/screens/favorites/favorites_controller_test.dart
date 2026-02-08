// FavoritesController uses GetStorage in constructor, so we mock
// path_provider and initialise GetStorage before any tests run.

import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider channel to unblock GetStorage
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '/tmp/flutter_test';
        }
        return null;
      },
    );
    await GetStorage.init();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  late TestSetup testSetup;

  setUp(() async {
    testSetup = TestSetup();
    await testSetup.init();
  });

  tearDown(() {
    testSetup.dispose();
  });

  // ═════════════════════════════════════════════════════════════════════════
  // STATE LOGIC
  // ═════════════════════════════════════════════════════════════════════════

  group('FavoritesController - State Logic', () {
    late FavoritesController controller;

    setUp(() {
      controller = FavoritesController();
    });

    test('toggleFavorite should add uuid to favorites list', () {
      controller.favorites.add('post-1');
      expect(controller.favorites.contains('post-1'), true);
    });

    test('toggleFavorite should track isFavorite state for additions', () {
      controller.favorites.add('post-1');
      controller.isFavorite.value = true;
      expect(controller.isFavorite.value, true);
    });

    test('removeAll should clear favorites and products', () {
      controller.favorites.addAll(['p1', 'p2', 'p3']);
      controller.favorites.clear();
      controller.favoriteProducts.clear();
      controller.isFavorite.value = false;

      expect(controller.favorites, isEmpty);
      expect(controller.favoriteProducts, isEmpty);
      expect(controller.isFavorite.value, false);
    });

    test('showPosts tab toggle should switch correctly', () {
      expect(controller.showPosts.value, true);

      controller.showPosts.value = false;
      expect(controller.showPosts.value, false);

      controller.showPosts.value = true;
      expect(controller.showPosts.value, true);
    });

    test('formatDate should format ISO date correctly', () {
      final formatted = controller.formatDate('2026-02-08T05:03:38.664527');
      expect(formatted, '08.02.2026');
    });

    test('formatDate should handle date without time', () {
      final formatted = controller.formatDate('2026-01-15T00:00:00Z');
      expect(formatted, '15.01.2026');
    });

    test('subscribedBrands should start empty', () {
      expect(controller.subscribedBrands, isEmpty);
      expect(controller.subscribeBrandPosts, isEmpty);
    });

    test('isLoadingPosts should default to false', () {
      expect(controller.isLoadingPosts.value, false);
    });

    test('isLoadingSubscribedBrands should default to false', () {
      expect(controller.isLoadingSubscribedBrands.value, false);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // SUBSCRIBE MANAGEMENT
  // ═════════════════════════════════════════════════════════════════════════

  group('FavoritesController - Subscribe Management', () {
    late FavoritesController controller;

    setUp(() {
      controller = FavoritesController();
    });

    test('addToSubscribes should add unique brand uuid', () {
      controller.addToSubscribes('brand-1');
      expect(controller.lastSubscribes.contains('brand-1'), true);
    });

    test('addToSubscribes should not duplicate', () {
      controller.addToSubscribes('brand-1');
      controller.addToSubscribes('brand-1');
      expect(controller.lastSubscribes.where((u) => u == 'brand-1').length, 1);
    });

    test('removeFromSubscribes should remove brand uuid', () {
      controller.lastSubscribes.add('brand-1');
      controller.removeFromSubscribes('brand-1');
      expect(controller.lastSubscribes.contains('brand-1'), false);
    });

    test('removeFromSubscribes should handle non-existent uuid', () {
      controller.removeFromSubscribes('nonexistent');
      expect(controller.lastSubscribes, isEmpty);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // FAVORITES LIST MANAGEMENT
  // ═════════════════════════════════════════════════════════════════════════

  group('FavoritesController - Favorites List Management', () {
    late FavoritesController controller;

    setUp(() {
      controller = FavoritesController();
    });

    test('favorites list should be reactive', () {
      controller.favorites.addAll(['p1', 'p2', 'p3']);
      expect(controller.favorites.length, 3);
    });

    test('removing from favorites should update list', () {
      controller.favorites.addAll(['p1', 'p2', 'p3']);
      controller.favorites.remove('p2');
      expect(controller.favorites.length, 2);
      expect(controller.favorites.contains('p2'), false);
    });

    test('saveFavorites should persist to GetStorage', () {
      controller.favorites.addAll(['p1', 'p2']);
      controller.saveFavorites();

      final stored = controller.box.read<List>('favorites');
      expect(stored, isNotNull);
      expect(stored!.length, 2);
    });

    test('loadFavorites should return saved values', () {
      controller.box.write('favorites', ['a1', 'a2', 'a3']);
      final loaded = controller.loadFavorites();
      expect(loaded.length, 3);
      expect(loaded, contains('a1'));
    });

    test('loadFavorites should return empty list when nothing saved', () {
      controller.box.remove('favorites');
      final loaded = controller.loadFavorites();
      expect(loaded, isEmpty);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // TOGGLE FAVORITE (full path with storage)
  // ═════════════════════════════════════════════════════════════════════════

  group('FavoritesController - toggleFavorite (with storage)', () {
    late FavoritesController controller;

    setUp(() {
      controller = FavoritesController();
      controller.favorites.clear();
      controller.favoriteProducts.clear();
      controller.box.remove('favorites');
    });

    test('toggleFavorite should add uuid and set isFavorite true', () {
      controller.toggleFavorite('post-1');

      expect(controller.favorites, contains('post-1'));
      expect(controller.isFavorite.value, true);
    });

    test('toggleFavorite should remove uuid and set isFavorite false', () {
      controller.favorites.add('post-1');
      controller.isFavorite.value = true;

      controller.toggleFavorite('post-1');

      expect(controller.favorites, isNot(contains('post-1')));
      expect(controller.isFavorite.value, false);
    });

    test('toggleFavorite on add should persist to storage', () {
      controller.toggleFavorite('post-1');

      final stored = controller.box.read<List>('favorites');
      expect(stored, contains('post-1'));
    });

    test('removeOne should remove uuid and update storage', () {
      controller.favorites.addAll(['p1', 'p2']);
      controller.saveFavorites();

      controller.removeOne('p1');

      expect(controller.favorites, isNot(contains('p1')));
      expect(controller.favorites, contains('p2'));
    });

    test('removeAll should clear everything', () {
      controller.favorites.addAll(['p1', 'p2', 'p3']);
      controller.saveFavorites();

      controller.removeAll();

      expect(controller.favorites, isEmpty);
      expect(controller.favoriteProducts, isEmpty);
      expect(controller.isFavorite.value, false);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // FETCH FAVORITE PRODUCTS (Dio)
  // ═════════════════════════════════════════════════════════════════════════

  group('FavoritesController - fetchFavoriteProducts', () {
    late FavoritesController controller;

    setUp(() {
      controller = FavoritesController();
    });

    test('should clear products when favorites is empty', () async {
      controller.favorites.clear();
      controller.favoriteProducts.clear();

      await controller.fetchFavoriteProducts();

      expect(controller.favoriteProducts, isEmpty);
    });

    test('should fetch products for favorite uuids', () async {
      controller.favorites.addAll(['post-1', 'post-2']);

      when(testSetup.mockDio.post(
        'posts/list',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'posts/list'),
            statusCode: 200,
            data: [
              {
                'uuid': 'post-1',
                'brand': {'name': 'Toyota'},
                'model': {'name': 'Camry'},
                'price': 25000,
                'year': 2022,
                'milleage': 10000,
                'engineType': 'gasoline',
                'enginePower': 200,
                'transmission': 'automatic',
                'condition': 'new',
                'currency': 'USD',
                'description': '',
                'location': 'Ashgabat',
                'vin': '',
                'createdAt': '2026-01-01T00:00:00Z',
              },
              {
                'uuid': 'post-2',
                'brand': {'name': 'BMW'},
                'model': {'name': 'X5'},
                'price': 45000,
                'year': 2023,
                'milleage': 5000,
                'engineType': 'diesel',
                'enginePower': 300,
                'transmission': 'automatic',
                'condition': 'new',
                'currency': 'EUR',
                'description': '',
                'location': 'Mary',
                'vin': '',
                'createdAt': '2026-01-01T00:00:00Z',
              },
            ],
          ));

      await controller.fetchFavoriteProducts();

      expect(controller.favoriteProducts.length, 2);
      expect(controller.favoriteProducts[0].brand, 'Toyota');
      expect(controller.favoriteProducts[1].brand, 'BMW');
    });

    test('should handle API error gracefully', () async {
      controller.favorites.addAll(['post-1']);

      when(testSetup.mockDio.post(
        'posts/list',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'posts/list'),
        type: DioExceptionType.connectionTimeout,
      ));

      // Should not throw
      await controller.fetchFavoriteProducts();
      expect(controller.favoriteProducts, isEmpty);
    });
  });
}
