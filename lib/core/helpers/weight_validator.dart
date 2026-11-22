/// Shared weight validation used by onboarding and the profile screen.
///
/// Bounds are inclusive, matching the "between 1 and 500 kg" hint
/// shown to the user.
const double kMinWeightKg = 1;
const double kMaxWeightKg = 500;

const String kWeightRangeError = 'Weight must be between 1 and 500 kg';

bool isValidWeight(double? weight) {
  if (weight == null || weight.isNaN) return false;
  return weight >= kMinWeightKg && weight <= kMaxWeightKg;
}
