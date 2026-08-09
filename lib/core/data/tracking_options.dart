import 'package:flutter/material.dart';

enum TrackingOption { refresh, high, eco }

const List<Map<String, Object>> trackingOptions = [
  {
    'label': 'Refresh Tracking',
    'value': TrackingOption.refresh,
    'icon': Icons.refresh,
  },

  {
    'label': 'High Tracking',
    'value': TrackingOption.high,
    'icon': Icons.gps_fixed,
  },

  {
    'label': 'Eco Tracking',
    'value': TrackingOption.eco,
    'icon': Icons.energy_savings_leaf,
  },
];
