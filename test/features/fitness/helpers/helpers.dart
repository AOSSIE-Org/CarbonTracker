import 'package:health/health.dart';

// Fake HealthDataPoint generator for testing.

HealthDataPoint fakeHealthPoint({
  required HealthDataType type,
  required num value,
  DateTime? dateTo,
}) {
  final t = dateTo ?? DateTime(2026, 1, 1, 8);
  return HealthDataPoint(
    uuid: 'test-${type.name}-$value-${t.millisecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: t,
    dateTo: t,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'test-device',
    sourceId: 'test-source',
    sourceName: 'test-source-name',
  );
}

// Helper to extract a stat value from the list of StatCardData by label.

String statValue(List stats, String label) =>
    (stats.firstWhere((s) => s.label == label) as dynamic).value as String;
