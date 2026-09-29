import 'package:carbon_tracker/core/enums/comparison_modes.dart';

class CarbonCalculator {
  static const busEmissionFactor = 90; // ~90 g CO₂ per km
  static const carEmissionFactor = 250; // ~250 g CO₂ per km
  static const baseEmissionFactor = 100; // ~100 g CO₂ per km for general
  static const electricCarEmissionFactor = 60;

  // Approximate value based on ICCT 2025 EU life-cycle emissions estimate.
  // Actual EV emissions vary with electricity mix, vehicle efficiency, etc.

  static double emissionSaved(ComparisonTransportMode mode, double distanceKm) {
    // Calculates carbon emissions for a trip
    switch (mode) {
      case ComparisonTransportMode.bus:
        return distanceKm * busEmissionFactor;
      case ComparisonTransportMode.car:
        return distanceKm * carEmissionFactor;
      case ComparisonTransportMode.electricCar:
        return distanceKm * electricCarEmissionFactor;
    }
  }
}
