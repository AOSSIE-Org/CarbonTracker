import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import '../helpers/helpers.dart';
import 'health_service.dart';

void main() {
  group('HealthService.aggregateFitnessMetrics', () {
    test('empty input produces zeroed / N-A metrics', () {
      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: [],
        steps: 0,
      );

      expect(statValue(stats, 'Steps'), '0');
      expect(statValue(stats, 'Calories Burned'), '0.0');
      expect(statValue(stats, 'Distance Covered'), '0.0');
      expect(statValue(stats, 'Floors Climbed'), '0');
      expect(statValue(stats, 'Heart Rate'), 'N/A');
      expect(statValue(stats, 'Blood Pressure'), 'N/A');
    });

    test('steps pass through unchanged', () {
      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: [],
        steps: 4321,
      );

      expect(statValue(stats, 'Steps'), '4321');
    });

    test('sums multiple distance points', () {
      final data = [
        fakeHealthPoint(type: HealthDataType.DISTANCE_DELTA, value: 250.0),
        fakeHealthPoint(type: HealthDataType.DISTANCE_DELTA, value: 400.25),
      ];

      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: data,
        steps: 0,
      );

      expect(statValue(stats, 'Distance Covered'), '650.3');
    });

    test('sums multiple calorie points', () {
      final data = [
        fakeHealthPoint(
          type: HealthDataType.TOTAL_CALORIES_BURNED,
          value: 120.0,
        ),
        fakeHealthPoint(
          type: HealthDataType.TOTAL_CALORIES_BURNED,
          value: 80.0,
        ),
      ];

      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: data,
        steps: 0,
      );

      expect(statValue(stats, 'Calories Burned'), '200.0');
    });

    test('floors climbed truncates per-point before summing', () {
      final data = [
        fakeHealthPoint(type: HealthDataType.FLIGHTS_CLIMBED, value: 2.0),
        fakeHealthPoint(type: HealthDataType.FLIGHTS_CLIMBED, value: 1.9),
      ];

      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: data,
        steps: 0,
      );

      // 2.toInt() + 1.9.toInt() == 2 + 1 == 3, not 3.9 rounded to 4.
      expect(statValue(stats, 'Floors Climbed'), '3');
    });

    test('heart rate uses the most recent reading, not the first', () {
      final earlier = DateTime(2026, 1, 1, 8, 0);
      final later = DateTime(2026, 1, 1, 12, 0);
      final data = [
        fakeHealthPoint(
          type: HealthDataType.HEART_RATE,
          value: 70.0,
          dateTo: earlier,
        ),
        fakeHealthPoint(
          type: HealthDataType.HEART_RATE,
          value: 88.0,
          dateTo: later,
        ),
      ];

      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: data,
        steps: 0,
      );

      expect(statValue(stats, 'Heart Rate'), '88');
    });

    test('falls back to watch heart rate when no HR point is present', () {
      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: [],
        steps: 0,
        watchHeartRateFallback: 75.0,
      );

      expect(statValue(stats, 'Heart Rate'), '75');
    });

    test('in-app HR reading takes priority over the watch fallback', () {
      final data = [
        fakeHealthPoint(type: HealthDataType.HEART_RATE, value: 90.0),
      ];

      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: data,
        steps: 0,
        watchHeartRateFallback: 60.0,
      );

      expect(statValue(stats, 'Heart Rate'), '90');
    });

    test('unhandled point types are ignored without throwing', () {
      final data = [fakeHealthPoint(type: HealthDataType.STEPS, value: 999)];

      expect(
        () => HealthService.aggregateFitnessMetrics(
          healthDataList: data,
          steps: 0,
        ),
        returnsNormally,
      );
    });

    test('blood pressure always reads N/A (feature not implemented)', () {
      final data = [
        fakeHealthPoint(
          type: HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
          value: 120.0,
        ),
        fakeHealthPoint(
          type: HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
          value: 80.0,
        ),
      ];

      final stats = HealthService.aggregateFitnessMetrics(
        healthDataList: data,
        steps: 0,
      );

      expect(statValue(stats, 'Blood Pressure'), 'N/A');
    });
  });
}
