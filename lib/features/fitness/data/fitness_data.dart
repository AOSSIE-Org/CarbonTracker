import 'package:flutter/material.dart';

class StatCardData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String unit;
  final String status;

  StatCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.unit = '',
    this.status = 'normal',
  });
}

class FitnessMetrics {
  final int steps;
  final double distance;
  final double caloriesBurned;
  final int floorsClimbed;
  final double heartRate;
  final double bloodPressureSystolic;
  final double bloodPressureDiastolic;

  FitnessMetrics({
    required this.steps,
    required this.distance,
    required this.caloriesBurned,
    required this.floorsClimbed,
    required this.heartRate,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
  });

  List<StatCardData> getStats() {
    return [
      StatCardData(
        icon: Icons.directions_walk_rounded,
        iconColor: const Color(0xFF0891B2),
        iconBg: const Color(0xFFECFEFF),
        label: 'Steps',
        value: steps.toString(),
        unit: 'steps',
      ),
      StatCardData(
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFE8622A),
        iconBg: const Color(0xFFFFF0E8),
        label: 'Calories Burned',
        value: caloriesBurned.toStringAsFixed(1),
        unit: 'cal',
      ),
      StatCardData(
        icon: Icons.location_on,
        iconColor: const Color(0xFF4A90D9),
        iconBg: const Color(0xFFE8F2FB),
        label: 'Distance Covered',
        value: distance.toStringAsFixed(1),
        unit: 'm',
      ),
      StatCardData(
        icon: Icons.stairs,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF3E8FF),
        label: 'Floors Climbed',
        value: floorsClimbed.toString(),
        unit: 'floors',
      ),
      StatCardData(
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBg: const Color(0xFFFEF2F2),
        label: 'Heart Rate',
        value: heartRate != 0 ? heartRate.toStringAsFixed(0) : 'N/A',
        // This data is available only when a watch is connected and heart rate monitoring is enabled
        unit: 'bpm',
      ),
      StatCardData(
        icon: Icons.bloodtype_rounded,
        iconColor: const Color(0xFF059669),
        iconBg: const Color(0xFFECFDF5),
        label: 'Blood Pressure',
        value: bloodPressureSystolic != 0 && bloodPressureDiastolic != 0
            ? '$bloodPressureSystolic/$bloodPressureDiastolic'
            : 'N/A',
        unit: 'mmHg',
        // This data is available only when a watch is connected and heart rate monitoring is enabled
      ),
    ];
  }
}

class ActivityType {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const ActivityType({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class ActivityIcons {
  ActivityIcons._();

  static const run = ActivityType(
    icon: Icons.directions_run_rounded,
    iconColor: Color(0xFF7C3AED),
    bgColor: Color(0xFFF3E8FF),
  );

  static const walk = ActivityType(
    icon: Icons.directions_walk_rounded,
    iconColor: Color(0xFF059669),
    bgColor: Color(0xFFECFDF5),
  );

  static const bike = ActivityType(
    icon: Icons.directions_bike_rounded,
    iconColor: Color(0xFFDC2626),
    bgColor: Color(0xFFFEF2F2),
  );

  static const jog = ActivityType(
    icon: Icons.directions_run_rounded,
    iconColor: Color(0xFFD97706),
    bgColor: Color(0xFFFFF7ED),
  );
}

class Activity {
  final String name;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String calories;
  final String distance;
  final String pace;

  Activity({
    required this.name,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.calories,
    required this.distance,
    required this.pace,
  });
}

final List<Activity> activities = [
  Activity(
    name: 'Morning Run',
    time: 'Today, 7:00 AM',
    icon: ActivityIcons.run.icon,
    iconColor: ActivityIcons.run.iconColor,
    bgColor: ActivityIcons.run.bgColor,
    calories: '300',
    distance: '5.0',
    pace: "6'00\"",
  ),
  Activity(
    name: 'Evening Walk',
    time: 'Yesterday, 6:30 PM',
    icon: ActivityIcons.walk.icon,
    iconColor: ActivityIcons.walk.iconColor,
    bgColor: ActivityIcons.walk.bgColor,
    calories: '150',
    distance: '3.2',
    pace: "8'00\"",
  ),
  Activity(
    name: 'Cycling',
    time: 'Yesterday, 5:00 PM',
    icon: ActivityIcons.bike.icon,
    iconColor: ActivityIcons.bike.iconColor,
    bgColor: ActivityIcons.bike.bgColor,
    calories: '400',
    distance: '10.0',
    pace: "3'00\"",
  ),
];

const metricsModalData = '''
Some health metrics, such as heart rate, blood pressure, and similar readings, are collected by compatible smartwatches rather than your phone.

On iOS, these metrics are available when an Apple Watch is connected and syncing data with Apple Health.

On Android, the required smartwatch app (such as Samsung Health, Fitbit, Garmin, etc.) must be connected to Health Connect and actively syncing data.

If your watch isn’t connected or syncing, these metrics may not appear in the app.
''';
