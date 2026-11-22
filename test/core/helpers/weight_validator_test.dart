import 'package:carbon_tracker/core/helpers/weight_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidWeight', () {
    test('accepts the inclusive boundaries 1 and 500', () {
      expect(isValidWeight(1), isTrue);
      expect(isValidWeight(500), isTrue);
    });

    test('accepts values inside the range', () {
      expect(isValidWeight(1.5), isTrue);
      expect(isValidWeight(65), isTrue);
      expect(isValidWeight(499.9), isTrue);
    });

    test('rejects values outside the range', () {
      expect(isValidWeight(0), isFalse);
      expect(isValidWeight(0.99), isFalse);
      expect(isValidWeight(500.01), isFalse);
      expect(isValidWeight(501), isFalse);
      expect(isValidWeight(-10), isFalse);
    });

    test('rejects null and NaN', () {
      expect(isValidWeight(null), isFalse);
      expect(isValidWeight(double.nan), isFalse);
    });
  });
}
