import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/features/carbon/helpers/carbon_calculator.dart';

void main() {
  group('CarbonCalculator.emissionSaved', () {
    test('calculates bus emissions correctly', () {
      final result = CarbonCalculator.emissionSaved(
        ComparisonTransportMode.bus,
        10,
      );

      expect(result, 900);
    });

    test('calculates car emissions correctly', () {
      final result = CarbonCalculator.emissionSaved(
        ComparisonTransportMode.car,
        10,
      );

      expect(result, 2500);
    });

    test('calculates electric car emissions correctly', () {
      final result = CarbonCalculator.emissionSaved(
        ComparisonTransportMode.electricCar,
        10,
      );

      expect(result, 600);
    });

    test('returns zero emissions for zero distance', () {
      final result = CarbonCalculator.emissionSaved(
        ComparisonTransportMode.car,
        0,
      );

      expect(result, 0);
    });

    test('handles decimal distances correctly', () {
      final result = CarbonCalculator.emissionSaved(
        ComparisonTransportMode.bus,
        2.5,
      );

      expect(result, 225);
    });
  });
}
