import 'package:flutter_test/flutter_test.dart';
import 'package:casinoloyalty_flutter/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns error for empty email', () {
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail(null), isNotNull);
      });

      test('returns error for invalid email format', () {
        expect(Validators.validateEmail('invalid'), isNotNull);
        expect(Validators.validateEmail('invalid@'), isNotNull);
        expect(Validators.validateEmail('@domain.com'), isNotNull);
        expect(Validators.validateEmail('user@domain'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.validateEmail('user@domain.com'), isNull);
        expect(Validators.validateEmail('user.name@domain.com'), isNull);
        expect(Validators.validateEmail('user+tag@domain.co.uk'), isNull);
      });
    });

    group('validateNotEmpty', () {
      test('returns error for empty value', () {
        expect(Validators.validateNotEmpty('', 'Campo'), isNotNull);
        expect(Validators.validateNotEmpty(null, 'Campo'), isNotNull);
        expect(Validators.validateNotEmpty('   ', 'Campo'), isNotNull);
      });

      test('returns null for non-empty value', () {
        expect(Validators.validateNotEmpty('valor', 'Campo'), isNull);
        expect(Validators.validateNotEmpty('  valor  ', 'Campo'), isNull);
      });
    });

    group('validateRut', () {
      test('returns error for empty RUT', () {
        expect(Validators.validateRut(''), isNotNull);
        expect(Validators.validateRut(null), isNotNull);
      });

      test('returns error for invalid RUT', () {
        expect(Validators.validateRut('12345678-0'), isNotNull);
        // 11.111.111-1 es un RUT con dígito verificador válido.
        expect(Validators.validateRut('11111111-2'), isNotNull);
      });

      test('returns null for valid RUT', () {
        expect(Validators.validateRut('12.345.678-5'), isNull);
        expect(Validators.validateRut('123456785'), isNull);
        expect(Validators.validateRut('12345678-5'), isNull);
      });
    });

    group('validatePhoneChile', () {
      test('returns error for invalid phone', () {
        expect(Validators.validatePhoneChile(''), isNotNull);
        expect(Validators.validatePhoneChile('12345'), isNotNull);
        expect(Validators.validatePhoneChile('1234567890'), isNotNull);
      });

      test('returns null for valid Chilean phone', () {
        expect(Validators.validatePhoneChile('912345678'), isNull);
        expect(Validators.validatePhoneChile('9 1234 5678'), isNull);
        expect(Validators.validatePhoneChile('+56 9 1234 5678'), isNull);
      });
    });

    group('validateLatitude', () {
      test('returns error for out of range latitude', () {
        expect(Validators.validateLatitude(-91), isNotNull);
        expect(Validators.validateLatitude(91), isNotNull);
        expect(Validators.validateLatitude(null), isNotNull);
      });

      test('returns null for valid latitude', () {
        expect(Validators.validateLatitude(0), isNull);
        expect(Validators.validateLatitude(-90), isNull);
        expect(Validators.validateLatitude(90), isNull);
        expect(Validators.validateLatitude(-33.4489), isNull);
      });
    });

    group('validateLongitude', () {
      test('returns error for out of range longitude', () {
        expect(Validators.validateLongitude(-181), isNotNull);
        expect(Validators.validateLongitude(181), isNotNull);
        expect(Validators.validateLongitude(null), isNotNull);
      });

      test('returns null for valid longitude', () {
        expect(Validators.validateLongitude(0), isNull);
        expect(Validators.validateLongitude(-180), isNull);
        expect(Validators.validateLongitude(180), isNull);
        expect(Validators.validateLongitude(-70.6693), isNull);
      });
    });
  });
}
