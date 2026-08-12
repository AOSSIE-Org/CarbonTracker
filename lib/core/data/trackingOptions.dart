import 'package:carbon_tracker/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

enum trackingOption { refresh, high, eco }

List<Map<String, Object>> trackingOptions = [
  {
    'label': "${trackingOption.refresh.name.capitalize()} Tracking",
    'value': trackingOption.refresh,
    'icon': Icons.refresh,
  },
  {'label': "${trackingOption.high.name.capitalize()} Tracking", 'value': trackingOption.high,'icon': Icons.gps_fixed},
  {'label': "${trackingOption.eco.name.capitalize()} Tracking",'value': trackingOption.eco, 'icon': Icons.energy_savings_leaf},
];
