import 'package:carbon_tracker/core/enums/transport_modes.dart';
import 'package:carbon_tracker/features/carbon/helpers/carbon_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates car emissions for 100 km correctly', () {
    final result = CarbonCalculator.emission(
      TransportModes.car,
      100, // distance in kilometers
    );
    expect(result, 25000); // 100 km * 250 g CO₂/km
  });

  test('calculates car carbon savings for 100 km correctly', () {
    final result = CarbonCalculator.savings(
      TransportModes.car,
      100, // distance in kilometers
    );
    expect(
      result,
      0,
    ); // base emission - emission for car
  });
}
