import 'dart:io';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:carbon_tracker/wearable/watch_service.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService implements IHealthService {
  static final HealthService _instance = HealthService._internal();
  static final _health = Health();

  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.HEART_RATE,
    HealthDataType.FLIGHTS_CLIMBED,
    Platform.isIOS
        ? HealthDataType.DISTANCE_WALKING_RUNNING
        : HealthDataType.DISTANCE_DELTA,
    Platform.isIOS
        ? HealthDataType.ACTIVE_ENERGY_BURNED
        : HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  HealthService._internal({
    Future<List<HealthDataPoint>> Function()? fetchHealthData,
    Future<int> Function()? fetchTodaySteps,
    Future<double?> Function()? fetchWatchHeartRate,
  }) : _fetchHealthData = fetchHealthData,
       _fetchTodaySteps = fetchTodaySteps,
       _fetchWatchHeartRate = fetchWatchHeartRate;

  final Future<List<HealthDataPoint>> Function()? _fetchHealthData;
  final Future<int> Function()? _fetchTodaySteps;
  final Future<double?> Function()? _fetchWatchHeartRate;

  factory HealthService() => _instance;

  @visibleForTesting
  factory HealthService.test({
    required Future<List<HealthDataPoint>> Function() fetchHealthData,
    required Future<int> Function() fetchTodaySteps,
    required Future<double?> Function() fetchWatchHeartRate,
  }) => HealthService._internal(
    fetchHealthData: fetchHealthData,
    fetchTodaySteps: fetchTodaySteps,
    fetchWatchHeartRate: fetchWatchHeartRate,
  );

  @override
  Future<void> initialize() async {
    try {
      await _health.configure();
    } catch (e) {
      debugPrint('Failed to initialize HealthService : $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasGrantedPermissions() async {
    try {
      return (await _health.hasPermissions(_types)) ?? false;
    } catch (e) {
      debugPrint('Failed to check permissions : $e');
      return false;
    }
  }

  // Request permissions to access health data

  @override
  Future<bool> requestPermissions() async {
    try {
      await _instance.initialize();
      bool isAuthorized = await hasGrantedPermissions();

      if (isAuthorized) {
        return true;
      }

      return await _health.requestAuthorization(_types);
    } catch (e) {
      debugPrint('Failed to request permissions : $e');
      return false;
    }
  }

  // Get today's steps

  @override
  Future<int> getTodaySteps() async {
    try {
      DateTime now = DateTime.now();
      DateTime midnight = DateTime(now.year, now.month, now.day);

      return await _health.getTotalStepsInInterval(midnight, now) ?? 0;
    } catch (e) {
      debugPrint('Failed to fetch steps : $e');
      return 0;
    }
  }

  // Get health data for today

  @override
  Future<List<HealthDataPoint>> getHealthData() async {
    try {
      DateTime now = DateTime.now();
      DateTime midnight = DateTime(now.year, now.month, now.day);

      return await _health.getHealthDataFromTypes(
        types: _types,
        startTime: midnight,
        endTime: now,
      );
    } catch (e) {
      debugPrint('Failed to fetch health data : $e');
      return [];
    }
  }

  /// Pure aggregation logic, extracted so it can be unit tested without
  /// touching the Health plugin or WatchService. Same behavior as the
  /// original inline loop

  @visibleForTesting
  static List<StatCardData> aggregateFitnessMetrics({
    required List<HealthDataPoint> healthDataList,
    required int steps,
    double? watchHeartRateFallback,
  }) {
    double distanceSum = 0.0;
    double caloriesSum = 0.0;
    double? heartRate;
    int? systolicCount;
    int? diastolicCount;
    int floorsClimbed = 0;
    DateTime? latestHeartRateTime;
    final systolicReadings = <({int value, DateTime time})>[];
    final diastolicReadings = <({int value, DateTime time})>[];

    for (final point in healthDataList) {
      HealthValue value = point.value;

      debugPrint('Health Data Point: ${point.type}');

      if (value is NumericHealthValue) {
        if (point.type == HealthDataType.DISTANCE_WALKING_RUNNING ||
            point.type == HealthDataType.DISTANCE_DELTA) {
          distanceSum += value.numericValue;
        } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED ||
            point.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          caloriesSum += value.numericValue;
        } else if (point.type == HealthDataType.FLIGHTS_CLIMBED) {
          floorsClimbed += value.numericValue.toInt();
        } else if (point.type == HealthDataType.HEART_RATE) {
          if (latestHeartRateTime == null ||
              point.dateTo.isAfter(latestHeartRateTime)) {
            latestHeartRateTime = point.dateTo;
            heartRate = value.numericValue.toDouble();
          }
        } else if (point.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
          systolicReadings.add((
            value: value.numericValue.toInt(),
            time: point.dateTo,
          ));
        } else if (point.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
          diastolicReadings.add((
            value: value.numericValue.toInt(),
            time: point.dateTo,
          ));
        }
      }
    }

    if (systolicReadings.isNotEmpty && diastolicReadings.isNotEmpty) {
      systolicReadings.sort((a, b) => b.time.compareTo(a.time));
      diastolicReadings.sort((a, b) => b.time.compareTo(a.time));

      for (final s in systolicReadings) {
        for (final d in diastolicReadings) {
          if (s.time == d.time) {
            systolicCount = s.value;
            diastolicCount = d.value;
            break;
          }
        }
        if (systolicCount != null && diastolicCount != null) {
          break;
        }
      }
    }

    heartRate ??= watchHeartRateFallback;

    return FitnessMetrics(
      steps: steps,
      distance: distanceSum,
      caloriesBurned: caloriesSum,
      floorsClimbed: floorsClimbed,
      heartRate: heartRate,
      bloodPressureSystolic: systolicCount,
      bloodPressureDiastolic: diastolicCount,
    ).getStats();
  }

  // Generate fitness metrics data from health data

  @override
  Future<List<StatCardData>> generateData() async {
    final fetchHealthData = _fetchHealthData ?? getHealthData;
    final fetchTodaySteps = _fetchTodaySteps ?? getTodaySteps;
    final fetchWatchHeartRate =
        _fetchWatchHeartRate ?? WatchService.getHeartRate;

    try {
      final healthDataList = await fetchHealthData();
      final steps = await fetchTodaySteps();
      final watchHeartRate = await fetchWatchHeartRate();

      return aggregateFitnessMetrics(
        healthDataList: healthDataList,
        steps: steps,
        watchHeartRateFallback: watchHeartRate,
      );
    } catch (e) {
      debugPrint('Failed to fetch health data : $e');
      return aggregateFitnessMetrics(healthDataList: [], steps: 0);
    }
  }
}
