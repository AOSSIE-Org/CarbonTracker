import 'package:carbon_tracker/database/models/base_model.dart';

class ActivityData extends BaseModel {
  final String activityType;
  final int startTime;
  final double? heartRate;
  final int? endTime;
  final double distance;
  final double caloriesBurned;
  final int lastUpdated;

  ActivityData({
    super.id,
    required this.activityType,
    required this.startTime,
    this.heartRate,
    this.endTime,
    this.distance = 0.0,
    this.caloriesBurned = 0.0,
    required this.lastUpdated,
  });

  factory ActivityData.fromMap(Map<String, dynamic> map) {
    final int start = map['startTime'] as int;
    final int? end = map['endTime'] as int?;

    return ActivityData(
      id: map['id'],
      activityType: map['activityType'],
      startTime: start,
      heartRate: map['heartRate'] != null
          ? (map['heartRate'] as num).toDouble()
          : null,
      endTime: end,
      distance: map['distance'] != null
          ? (map['distance'] as num).toDouble()
          : 0.0,
      caloriesBurned: map['caloriesBurned'] != null
          ? (map['caloriesBurned'] as num).toDouble()
          : 0.0,
      lastUpdated: (map['lastUpdated'] as num?)?.toInt() ?? end ?? start,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityType': activityType,
      'startTime': startTime,
      'heartRate': heartRate,
      'endTime': endTime,
      'distance': distance,
      'caloriesBurned': caloriesBurned,
      'lastUpdated': lastUpdated,
    };
  }
}

enum ActivityKind {
  running,
  walking,
  biking;

  String toDb() => name;

  static ActivityKind fromDb(String value) =>
      ActivityKind.values.firstWhere((e) {
        return e.name == value.toLowerCase();
      }, orElse: () => throw ArgumentError('Unknown activity type: $value'));

  String get label => switch (this) {
    ActivityKind.running => 'Running',
    ActivityKind.walking => 'Walking',
    ActivityKind.biking => 'Cycling',
  };
}
