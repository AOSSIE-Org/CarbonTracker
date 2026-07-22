import 'package:carbon_tracker/core/enums/transport_modes.dart';

class CarbonCalculator {
  static const busEmissionFactor = 90; // ~90 g CO₂ per km
  static const carEmissionFactor = 250; // ~250 g CO₂ per km
  static const footEmissionFactor = 0; // ~0 g CO₂ per km
  static const baseEmissionFactor = 100; // ~100 g CO₂ per km for general

  static double emission(TransportModes transportMode, double distanceKm) {
    // Calculates carbon emissions for a trip
    switch (transportMode) {
      case TransportModes.bus:
        return distanceKm * busEmissionFactor;
      case TransportModes.car:
        return distanceKm * carEmissionFactor;
      case TransportModes.foot:
        return distanceKm * footEmissionFactor;
      case TransportModes.cycle:
        return distanceKm * footEmissionFactor;
    }
  }

  static double savings(TransportModes transportMode, double distanceKm) {
    // Calculates carbon savings for a trip

    double hypotheticalEmission = distanceKm * baseEmissionFactor;
    final saved = hypotheticalEmission - emission(transportMode, distanceKm);

    return saved < 0 ? 0 : saved;
  }
}
