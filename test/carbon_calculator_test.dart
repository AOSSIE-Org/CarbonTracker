import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/features/carbon/helpers/carbon_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates car carbon savings for 100 km correctly', () {
    final result = CarbonCalculator.emissionSaved(
      ComparisonTransportMode.car,
      100, // distance in kilometers
    );
    expect(result, 0); // base emission - emission for car
  });
}
