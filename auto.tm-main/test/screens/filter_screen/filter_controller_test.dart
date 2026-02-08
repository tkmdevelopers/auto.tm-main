// FilterController uses GetStorage in constructor, so we test its pure logic
// by instantiating within testWidgets (which provides bindings) and using
// TestWidgetsFlutterBinding + channel mocking for GetStorage.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';

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
    // Initialize GetStorage with the mocked path
    await GetStorage.init();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // QUERY BUILDING
  // ═════════════════════════════════════════════════════════════════════════

  group('FilterController - buildQuery', () {
    late FilterController controller;

    setUp(() {
      controller = FilterController();
    });

    test('should return empty string with no filters', () {
      controller.selectedBrandUuid.value = '';
      controller.selectedModelUuid.value = '';
      controller.selectedCountry.value = 'Local';
      controller.location.value = '';
      controller.transmission.value = '';
      controller.selectedColor.value = '';
      controller.credit.value = false;
      controller.exchange.value = false;
      controller.condition.value = 'All';

      final query = controller.buildQuery();
      expect(query, isEmpty);
    });

    test('should include brand filter', () {
      controller.selectedBrandUuid.value = 'brand-123';
      final query = controller.buildQuery();
      expect(query.contains('brandFilter=brand-123'), true);
    });

    test('should include model filter', () {
      controller.selectedModelUuid.value = 'model-456';
      final query = controller.buildQuery();
      expect(query.contains('modelFilter=model-456'), true);
    });

    test('should include transmission filter', () {
      controller.transmission.value = 'automatic';
      final query = controller.buildQuery();
      expect(query.contains('transmission=automatic'), true);
    });

    test('should include color filter', () {
      controller.selectedColor.value = 'red';
      final query = controller.buildQuery();
      expect(query.contains('color=red'), true);
    });

    test('should include credit when true', () {
      controller.credit.value = true;
      final query = controller.buildQuery();
      expect(query.contains('credit=true'), true);
    });

    test('should include exchange when true', () {
      controller.exchange.value = true;
      final query = controller.buildQuery();
      expect(query.contains('exchange=true'), true);
    });

    test('should not include credit/exchange when false', () {
      controller.credit.value = false;
      controller.exchange.value = false;
      final query = controller.buildQuery();
      expect(query.contains('credit'), false);
      expect(query.contains('exchange'), false);
    });

    test('should include condition when not All', () {
      controller.condition.value = 'new';
      final query = controller.buildQuery();
      expect(query.contains('condition=new'), true);
    });

    test('should not include condition when All', () {
      controller.condition.value = 'All';
      final query = controller.buildQuery();
      expect(query.contains('condition'), false);
    });

    test('should include year range', () {
      controller.minYear.value = '2020';
      controller.maxYear.value = '2025';
      final query = controller.buildQuery();
      expect(query.contains('minYear=2020'), true);
      expect(query.contains('maxYear=2025'), true);
    });

    test('should include location for Local with city', () {
      controller.selectedCountry.value = 'Local';
      controller.location.value = 'Ashgabat';
      final query = controller.buildQuery();
      expect(query.contains('location=Ashgabat'), true);
    });

    test('should not include location for Local without city', () {
      controller.selectedCountry.value = 'Local';
      controller.location.value = '';
      final query = controller.buildQuery();
      expect(query.contains('location'), false);
    });

    test('should include country as location for non-Local', () {
      controller.selectedCountry.value = 'Dubai';
      final query = controller.buildQuery();
      expect(query.contains('location=Dubai'), true);
    });

    test('should include enginePower from text field', () {
      controller.enginepowerController.text = '200';
      final query = controller.buildQuery();
      expect(query.contains('enginePower=200'), true);
    });

    test('should include milleage from text field', () {
      controller.milleageController.text = '50000';
      final query = controller.buildQuery();
      expect(query.contains('milleage=50000'), true);
    });

    test('should combine multiple filters', () {
      controller.selectedBrandUuid.value = 'brand-1';
      controller.transmission.value = 'automatic';
      controller.credit.value = true;
      controller.condition.value = 'new';
      final query = controller.buildQuery();
      expect(query.contains('brandFilter=brand-1'), true);
      expect(query.contains('transmission=automatic'), true);
      expect(query.contains('credit=true'), true);
      expect(query.contains('condition=new'), true);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // ACTIVE FILTER COUNT
  // ═════════════════════════════════════════════════════════════════════════

  group('FilterController - activeFilterCount', () {
    late FilterController controller;

    setUp(() {
      controller = FilterController();
    });

    test('should be 0 with no active filters', () {
      expect(controller.activeFilterCount, 0);
    });

    test('should count brand', () {
      controller.selectedBrandUuid.value = 'b1';
      expect(controller.activeFilterCount, 1);
    });

    test('should count model', () {
      controller.selectedModelUuid.value = 'm1';
      expect(controller.activeFilterCount, 1);
    });

    test('should count transmission', () {
      controller.transmission.value = 'automatic';
      expect(controller.activeFilterCount, 1);
    });

    test('should count credit and exchange separately', () {
      controller.credit.value = true;
      controller.exchange.value = true;
      expect(controller.activeFilterCount, 2);
    });

    test('should count year range as one', () {
      controller.minYear.value = '2020';
      controller.maxYear.value = '2024';
      expect(controller.activeFilterCount, 1);
    });

    test('should count color', () {
      controller.selectedColor.value = 'blue';
      expect(controller.activeFilterCount, 1);
    });

    test('should count premium as one', () {
      controller.premium.addAll(['s1', 's2']);
      expect(controller.activeFilterCount, 1);
    });

    test('should sum all active filters', () {
      controller.selectedBrandUuid.value = 'b1';
      controller.selectedModelUuid.value = 'm1';
      controller.transmission.value = 'manual';
      controller.credit.value = true;
      controller.exchange.value = true;
      controller.minYear.value = '2020';
      controller.selectedColor.value = 'red';
      expect(controller.activeFilterCount, 7);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // CLEAR FILTERS
  // ═════════════════════════════════════════════════════════════════════════

  group('FilterController - clearFilters', () {
    late FilterController controller;

    setUp(() {
      controller = FilterController();
    });

    test('should reset all filters except brand/model', () {
      controller.transmission.value = 'automatic';
      controller.credit.value = true;
      controller.exchange.value = true;
      controller.selectedColor.value = 'red';
      controller.condition.value = 'new';
      controller.minYear.value = '2020';
      controller.maxYear.value = '2025';
      controller.location.value = 'Ashgabat';
      controller.selectedCountry.value = 'Dubai';

      controller.clearFilters();

      expect(controller.transmission.value, '');
      expect(controller.credit.value, false);
      expect(controller.exchange.value, false);
      expect(controller.selectedColor.value, '');
      expect(controller.condition.value, 'All');
      expect(controller.minYear.value, '');
      expect(controller.maxYear.value, '');
      expect(controller.location.value, '');
      expect(controller.selectedCountry.value, 'Local');
    });

    test('should keep brand/model by default', () {
      controller.selectedBrand.value = 'Toyota';
      controller.selectedBrandUuid.value = 'b1';
      controller.clearFilters();
      expect(controller.selectedBrand.value, 'Toyota');
      expect(controller.selectedBrandUuid.value, 'b1');
    });

    test('should clear brand/model with includeBrandModel=true', () {
      controller.selectedBrand.value = 'Toyota';
      controller.selectedBrandUuid.value = 'b1';
      controller.selectedModel.value = 'Camry';
      controller.selectedModelUuid.value = 'm1';

      controller.clearFilters(includeBrandModel: true);

      expect(controller.selectedBrand.value, '');
      expect(controller.selectedBrandUuid.value, '');
      expect(controller.selectedModel.value, '');
      expect(controller.selectedModelUuid.value, '');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // BRAND/MODEL IN-MEMORY FILTERING
  // ═════════════════════════════════════════════════════════════════════════

  group('FilterController - filterBrands', () {
    late FilterController controller;

    setUp(() {
      controller = FilterController();
      controller.brands.value = [
        {'uuid': '1', 'name': 'Toyota'},
        {'uuid': '2', 'name': 'BMW'},
        {'uuid': '3', 'name': 'Mercedes-Benz'},
        {'uuid': '4', 'name': 'Hyundai'},
        {'uuid': '5', 'name': 'Toyota Motor'},
      ];
    });

    test('should show all when query is empty', () {
      controller.filterBrands('');
      expect(controller.filteredBrands.length, 5);
    });

    test('should filter by name case-insensitively', () {
      controller.filterBrands('toyo');
      expect(controller.filteredBrands.length, 2);
    });

    test('should find exact match', () {
      controller.filterBrands('BMW');
      expect(controller.filteredBrands.length, 1);
    });

    test('should return empty for no match', () {
      controller.filterBrands('Porsche');
      expect(controller.filteredBrands, isEmpty);
    });

    test('should handle whitespace query', () {
      controller.filterBrands('   ');
      expect(controller.filteredBrands.length, 5);
    });
  });

  group('FilterController - filterModels', () {
    late FilterController controller;

    setUp(() {
      controller = FilterController();
      controller.models.value = [
        {'uuid': '1', 'name': 'Camry'},
        {'uuid': '2', 'name': 'Corolla'},
        {'uuid': '3', 'name': 'RAV4'},
        {'uuid': '4', 'name': 'Camaro'},
      ];
    });

    test('should show all when query is empty', () {
      controller.filterModels('');
      expect(controller.filteredModels.length, 4);
    });

    test('should filter case-insensitively', () {
      controller.filterModels('cam');
      expect(controller.filteredModels.length, 2);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // SORT & PREMIUM
  // ═════════════════════════════════════════════════════════════════════════

  group('FilterController - sort and premium', () {
    late FilterController controller;

    setUp(() {
      controller = FilterController();
    });

    test('updateSortOption should change sort', () {
      controller.selectedSortOption.value = 'createdAt_desc';
      controller.updateSortOption('price_asc');
      expect(controller.selectedSortOption.value, 'price_asc');
    });

    test('togglePremium should add uuid', () {
      controller.togglePremium('sub-1');
      expect(controller.premium.contains('sub-1'), true);
    });

    test('togglePremium should remove existing uuid', () {
      controller.premium.add('sub-1');
      controller.togglePremium('sub-1');
      expect(controller.premium.contains('sub-1'), false);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // YEAR ACCESSORS
  // ═════════════════════════════════════════════════════════════════════════

  group('FilterController - year accessors', () {
    late FilterController controller;

    setUp(() {
      controller = FilterController();
    });

    test('effectiveMinYear returns empty when unset', () {
      expect(controller.effectiveMinYear, '');
    });

    test('effectiveMinYear returns value when set', () {
      controller.minYear.value = '2015';
      expect(controller.effectiveMinYear, '2015');
    });

    test('effectiveMaxYear returns value when set', () {
      controller.maxYear.value = '2024';
      expect(controller.effectiveMaxYear, '2024');
    });
  });
}
