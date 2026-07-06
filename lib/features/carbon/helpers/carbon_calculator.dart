class CarbonCalculator {
  static const busEmissionFactor = 90; // ~90 g CO₂ per km
  static const carEmissionFactor = 250; // ~250 g CO₂ per km
  static const footEmissionFactor = 0; // ~0 g CO₂ per km
  static const baseEmissionFactor = 100; // ~100 g CO₂ per km for general

  static double emission(String transportMode, double distanceKm) {
    // Calculates carbon emissions for a trip
    switch (transportMode) {
      case 'bus':
        return distanceKm * busEmissionFactor;
      case 'car':
        return distanceKm * carEmissionFactor;
      case 'foot':
      case 'cycle':
        return distanceKm * footEmissionFactor;
      default:
        throw Exception(
          'Unsupported transport mode: $transportMode',
        ); //  Remove this later
    }
  }

  static double savings(String transportMode, double distanceKm) {
    // Calculates carbon savings for a trip

    double hypotheticalEmission = distanceKm * baseEmissionFactor;
    final saved = hypotheticalEmission - emission(transportMode, distanceKm);

    return saved < 0 ? 0 : saved;
  }
}
