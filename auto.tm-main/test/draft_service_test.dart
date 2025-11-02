import 'package:flutter_test/flutter_test.dart';
import 'package:auto_tm/screens/post_screen/services/draft_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DraftService', () {
    late DraftService service;
    setUp(() async {
      service = DraftService();
    });

    test(
      'computeSignature stable for same snapshot and differs when changed',
      () {
        final s1 = {'a': 1, 'b': 'x'};
        final sig1 = service.computeSignature(s1);
        final sig2 = service.computeSignature({
          'b': 'x',
          'a': 1,
        }); // order variant
        expect(sig1, sig2);
        final sigChanged = service.computeSignature({'a': 1, 'b': 'y'});
        expect(sigChanged == sig1, isFalse);
      },
    );

    test('saveOrUpdateFromSnapshot (skipped - requires storage)', () async {
      expect(true, isTrue, reason: 'Skipped due to storage dependency');
    }, skip: true);
    test('clearAll removes drafts (skipped - requires storage)', () async {
      expect(true, isTrue, reason: 'Skipped due to storage dependency');
    }, skip: true);
    test(
      'upsert multiple drafts keeps max capacity (skipped - requires storage)',
      () async {
        expect(true, isTrue, reason: 'Skipped due to storage dependency');
      },
      skip: true,
    );
  });
}
