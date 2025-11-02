import 'package:flutter_test/flutter_test.dart';
import 'package:auto_tm/screens/post_screen/model/post_form_state.dart';

void main() {
  group('PostFormState', () {
    test('default is empty and hasAnyInput false', () {
      const state = PostFormState();
      expect(state.hasAnyInput, isFalse);
    });

    test('copyWith changes selective fields', () {
      const s1 = PostFormState(brandUuid: 'b', priceRaw: '100', year: 2024);
      final s2 = s1.copyWith(priceRaw: '200');
      expect(s2.priceRaw, '200');
      expect(s2.brandUuid, 'b');
      expect(s2.year, 2024);
      expect(s1 == s2, isFalse);
    });

    test('equality and hashCode stable', () {
      const a = PostFormState(brandUuid: 'x', modelUuid: 'y');
      const b = PostFormState(brandUuid: 'x', modelUuid: 'y');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('hasAnyInput true when any field populated', () {
      const s = PostFormState(description: 'Car');
      expect(s.hasAnyInput, isTrue);
    });

    test('map roundtrip preserves values', () {
      const orig = PostFormState(
        brandUuid: 'b1',
        modelUuid: 'm1',
        brandName: 'Brand',
        modelName: 'Model',
        condition: 'new',
        transmission: 'auto',
        engineType: 'petrol',
        year: 2024,
        priceRaw: '10000',
        currency: 'TMT',
        location: 'Ashgabat',
        credit: true,
        exchange: false,
        enginePowerRaw: '120',
        milleageRaw: '0',
        vin: 'VIN',
        description: 'Desc',
        phoneRaw: '60000000',
        title: 'My Car',
        phoneVerified: true,
      );
      final map = orig.toMap();
      final restored = PostFormState.fromMap(map);
      expect(restored, orig);
    });
  });
}
