import 'package:carbon_tracker/database/models/activity.dart';
import 'package:flutter/material.dart';

class ActivityStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const ActivityStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  factory ActivityStyle.forKind(ActivityKind kind) => switch (kind) {
    ActivityKind.running => const ActivityStyle(
      icon: Icons.directions_run_rounded,
      iconColor: Color(0xFF7C3AED),
      bgColor: Color(0xFFF3E8FF),
    ),
    ActivityKind.walking => const ActivityStyle(
      icon: Icons.directions_walk_rounded,
      iconColor: Color(0xFF059669),
      bgColor: Color(0xFFECFDF5),
    ),
    ActivityKind.biking => const ActivityStyle(
      icon: Icons.directions_bike_rounded,
      iconColor: Color(0xFFDC2626),
      bgColor: Color(0xFFFEF2F2),
    ),
  };
}
