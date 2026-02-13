import 'package:auto_tm/services/auth/phone_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneFormatter', () {
    group('isValidSubscriber', () {
      test('should accept valid subscriber starting with 6', () {
        expect(PhoneFormatter.isValidSubscriber('65000000'), true);
        expect(PhoneFormatter.isValidSubscriber('61234567'), true);
      });

      test('should accept valid subscriber starting with 7', () {
        expect(PhoneFormatter.isValidSubscriber('71234567'), true);
        expect(PhoneFormatter.isValidSubscriber('70000000'), true);
      });

      test('should reject subscriber with wrong prefix', () {
        expect(PhoneFormatter.isValidSubscriber('51234567'), false);
        expect(PhoneFormatter.isValidSubscriber('81234567'), false);
        expect(PhoneFormatter.isValidSubscriber('01234567'), false);
      });

      test('should reject subscriber with wrong length', () {
        expect(PhoneFormatter.isValidSubscriber('6500000'), false); // 7 digits
        expect(
          PhoneFormatter.isValidSubscriber('650000000'),
          false,
        ); // 9 digits
        expect(PhoneFormatter.isValidSubscriber('6'), false);
        expect(PhoneFormatter.isValidSubscriber(''), false);
      });

      test('should reject subscriber with non-digit characters', () {
        expect(PhoneFormatter.isValidSubscriber('6500000a'), false);
        expect(PhoneFormatter.isValidSubscriber('+9936500'), false);
        expect(PhoneFormatter.isValidSubscriber('65 000 00'), false);
      });
    });

    group('buildFullDigits', () {
      test('should prepend 993 country code', () {
        expect(PhoneFormatter.buildFullDigits('65000000'), '99365000000');
        expect(PhoneFormatter.buildFullDigits('71234567'), '99371234567');
      });
    });

    group('isValidFull', () {
      test('should accept valid full number with 993 prefix', () {
        expect(PhoneFormatter.isValidFull('99365000000'), true);
        expect(PhoneFormatter.isValidFull('99371234567'), true);
      });

      test('should reject invalid full number', () {
        expect(PhoneFormatter.isValidFull('99365000'), false); // too short
        expect(PhoneFormatter.isValidFull('1234567890'), false); // wrong prefix
        expect(PhoneFormatter.isValidFull('993650000001'), false); // too long
        expect(PhoneFormatter.isValidFull('99355000000'), false); // invalid 5
      });
    });

    group('extractSubscriber', () {
      test('should extract from +993 format', () {
        expect(PhoneFormatter.extractSubscriber('+99365000000'), '65000000');
      });

      test('should extract from 993 format', () {
        expect(PhoneFormatter.extractSubscriber('99365000000'), '65000000');
      });

      test('should extract from formatted number', () {
        expect(
          PhoneFormatter.extractSubscriber('+993 65 00 00 00'),
          '65000000',
        );
      });

      test('should return raw digits when no 993 prefix', () {
        expect(PhoneFormatter.extractSubscriber('65000000'), '65000000');
      });

      test('should handle empty input', () {
        expect(PhoneFormatter.extractSubscriber(''), '');
      });
    });
  });
}
