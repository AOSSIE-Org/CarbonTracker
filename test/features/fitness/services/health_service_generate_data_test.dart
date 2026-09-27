import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import '../helpers/helpers.dart';
import 'health_service.dart';

void main() {
  group('HealthService.generateData wiring', () {
    test(
      'wires fetched data + steps + watch HR through to the final stats',
      () async {
        final service = HealthService.test(
          fetchHealthData: () async => [
            fakeHealthPoint(type: HealthDataType.DISTANCE_DELTA, value: 500.0),
          ],
          fetchTodaySteps: () async => 8000,
          fetchWatchHeartRate: () async => 65.0,
        );

        final stats = await service.generateData();

        expect(statValue(stats, 'Steps'), '8000');
        expect(statValue(stats, 'Distance Covered'), '500.0');
        expect(statValue(stats, 'Heart Rate'), '65'); // no in-app HR point
      },
    );

    test('in-app HR point wins over watch fallback through the real '
        'orchestration path', () async {
      final service = HealthService.test(
        fetchHealthData: () async => [
          fakeHealthPoint(type: HealthDataType.HEART_RATE, value: 90.0),
        ],
        fetchTodaySteps: () async => 0,
        fetchWatchHeartRate: () async => 60.0,
      );

      final stats = await service.generateData();

      expect(statValue(stats, 'Heart Rate'), '90');
    });

    test('fetchHealthData throwing falls back to zeroed defaults', () async {
      final service = HealthService.test(
        fetchHealthData: () async => throw Exception('plugin unavailable'),
        fetchTodaySteps: () async => 8000,
        fetchWatchHeartRate: () async => 65.0,
      );

      final stats = await service.generateData();

      expect(statValue(stats, 'Steps'), '0');
      expect(statValue(stats, 'Heart Rate'), 'N/A');
    });

    test('fetchWatchHeartRate throwing discards already-fetched steps/health data', () async {
      final service = HealthService.test(
        fetchHealthData: () async => [
          fakeHealthPoint(type: HealthDataType.DISTANCE_DELTA, value: 500.0),
        ],
        fetchTodaySteps: () async => 8000,
        fetchWatchHeartRate: () async => throw Exception('watch offline'),
      );

      final stats = await service.generateData();

      expect(statValue(stats, 'Steps'), '0');
      expect(statValue(stats, 'Distance Covered'), '0.0');
    });
  });
}
