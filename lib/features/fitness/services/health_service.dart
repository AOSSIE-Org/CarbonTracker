import 'dart:io';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:health/health.dart';

class HealthService {
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

  HealthService._internal();

  factory HealthService() => _instance;

  static Future<void> initialize() async {
    try {
      await _health.configure();
    } catch (e) {
      debugPrint('Failed to initialize HealthService : $e');
      rethrow;
    }
  }

  static Future<bool> hasGrantedPermissions() async {
    try {
      return (await _health.hasPermissions(_types)) ?? false;
    } catch (e) {
      debugPrint('Failed to check permissions : $e');
      return false;
    }
  }

  // Request permissions to access health data

  static Future<bool> requestPermissions() async {
    try {
      await HealthService.initialize();
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

  static Future<int> getTodaySteps() async {
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

  static Future<List<HealthDataPoint>> getHealthData() async {
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

  // Generate fitness metrics data from health data

  static Future<List<StatCardData>> generateData() async {
    double distanceSum = 0.0;
    double caloriesSum = 0.0;
    double heartRate = 0.0;
    double bloodPressureSystolic = 0.0;
    double bloodPressureDiastolic = 0.0;
    int floorsClimbed = 0;
    int steps = 0;

    try {
      List<HealthDataPoint> healthDataList =
          await HealthService.getHealthData();

      steps = await HealthService.getTodaySteps();

      for (final point in healthDataList) {
        HealthValue value = point.value;

        debugPrint(
            'Health Data Point: ${point.type}');

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
            // to be implemented based on watch connection
          } else if (point.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
            // to be implemented
          }
          if (point.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
            // to be implemented based on watch connection
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch health data : $e');
    }

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
}
