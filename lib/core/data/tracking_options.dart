import 'package:carbon_tracker/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

enum TrackingOption { refresh, high, eco }

List<Map<String, Object>> trackingOptions = [
  {
    'label': "${TrackingOption.refresh.name.capitalize()} Tracking",
    'value': TrackingOption.refresh,
    'icon': Icons.refresh,
  },
  {'label': "${TrackingOption.high.name.capitalize()} Tracking", 'value': TrackingOption.high,'icon': Icons.gps_fixed},
  {'label': "${TrackingOption.eco.name.capitalize()} Tracking",'value': TrackingOption.eco, 'icon': Icons.energy_savings_leaf},
];
