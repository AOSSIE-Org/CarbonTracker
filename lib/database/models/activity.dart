import 'package:carbon_tracker/database/models/base_model.dart';
import 'package:flutter/cupertino.dart';

class ActivityData extends BaseModel {
  final String activityType;
  final int startTime;
  final double? heartRate;
  final int? endTime;
  final double distance;
  final double caloriesBurned;

  ActivityData({
    super.id,
    required this.activityType,
    required this.startTime,
    this.heartRate,
    this.endTime,
    this.distance = 0.0,
    this.caloriesBurned = 0.0,
  });

  factory ActivityData.fromMap(Map<String, dynamic> map) {
    return ActivityData(
      id: map['id'],
      activityType: map['activityType'],
      startTime: map['startTime'],
      heartRate: map['heartRate'] != null
          ? (map['heartRate'] as num).toDouble()
          : null,
      endTime: map['endTime'],
      distance: map['distance'] != null
          ? (map['distance'] as num).toDouble()
          : 0.0,
      caloriesBurned: map['caloriesBurned'] != null
          ? (map['caloriesBurned'] as num).toDouble()
          : 0.0,
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
