import 'package:carbon_tracker/features/map/helpers/time_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/core/enums/transport_modes.dart';

void main() {
  group('calculateTime', () {
    test('calculates walking time correctly', () {
      final result = calculateTime(10, TransportModes.walk);

      expect(result, 120);
    });

    test('calculates running time correctly', () {
      final result = calculateTime(10, TransportModes.run);

      expect(result, 75);
    });

    test('calculates cycling time correctly', () {
      final result = calculateTime(10, TransportModes.bike);

      expect(result, 40);
    });

    test('returns zero for zero distance', () {
      final result = calculateTime(0, TransportModes.walk);

      expect(result, 0);
    });

    test('handles decimal distance correctly', () {
      final result = calculateTime(2.5, TransportModes.walk);

      expect(result, 30);
    });
  });
}
