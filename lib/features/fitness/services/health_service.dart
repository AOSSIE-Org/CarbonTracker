import 'dart:io';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/wearable/watch_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';


abstract class IHealthService {
  Future<void> initialize();

  Future<bool> hasGrantedPermissions();

  Future<bool> requestPermissions();

  Future<int> getTodaySteps();

  Future<List<HealthDataPoint>> getHealthData();

  Future<List<StatCardData>> generateData();
}

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

  factory HealthService() => _instance;

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

  @visibleForTesting
  static List<StatCardData> aggregateFitnessMetrics({
    required List<HealthDataPoint> healthDataList,
    required int steps,
    double? watchHeartRateFallback,
  }) {
    double distanceSum = 0.0;
    double caloriesSum = 0.0;
    double? heartRate;
    double bloodPressureSystolic = 0.0;
    double bloodPressureDiastolic = 0.0;
    int floorsClimbed = 0;
    DateTime? latestHeartRateTime;

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
          // to be implemented
        }
        if (point.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
          // to be implemented based on watch connection
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
      bloodPressureSystolic: bloodPressureSystolic,
      bloodPressureDiastolic: bloodPressureDiastolic,
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
      double? watchHeartRate;

      try {
        watchHeartRate = await fetchWatchHeartRate();
      } catch (e) {
        debugPrint('Failed to fetch watch heart rate : $e');
      }

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

final healthServiceProvider = Provider<IHealthService>(
  (ref) => HealthService(),
);
