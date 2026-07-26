import 'dart:convert';

import 'package:carbon_tracker/database/models/base_model.dart';

class User extends BaseModel {
  final String name;
  final List<dynamic> preferredTransports;
  final List<dynamic> frequentTransports;
  final String
  trackingMode; // Default tracking mode; other modes will be supported later
  final double weight;
  final String? sustainabilityThoughts;
  final int lastResetMonth;
  final int lastResetYear;

  // Constructor with named parameters and default values

  User({
    super.id,
    required this.name,
    required this.preferredTransports,
    required this.frequentTransports,
    required this.weight,
    this.trackingMode = "refresh",
    this.sustainabilityThoughts,
    required this.lastResetMonth,
    required this.lastResetYear,
  });

  //Named constructor to create a User from a Map

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      preferredTransports: jsonDecode(map['preferred_transports']),
      frequentTransports: jsonDecode(map['frequent_transports']),
      trackingMode: map['tracking_mode'],
      weight: (map['weight'] as num).toDouble(),
      sustainabilityThoughts: map['sustainability_thoughts'],
      lastResetMonth: map['last_reset_month'],
      lastResetYear: map['last_reset_year'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'preferred_transports': jsonEncode(preferredTransports),
      'frequent_transports': jsonEncode(frequentTransports),
      'tracking_mode': trackingMode,
      'weight': weight,
      'sustainability_thoughts': sustainabilityThoughts,
      'last_reset_month': lastResetMonth,
      'last_reset_year': lastResetYear,
    };
  }

  User copyWith({
    String? name,
    List<dynamic>? preferredTransports,
    List<dynamic>? frequentTransports,
    String? trackingMode,
    double? weight,
    String? sustainabilityThoughts,
    int? lastResetMonth,
    int? lastResetYear,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      preferredTransports: preferredTransports ?? this.preferredTransports,
      frequentTransports: frequentTransports ?? this.frequentTransports,
      trackingMode: trackingMode ?? this.trackingMode,
      weight: weight ?? this.weight,
      sustainabilityThoughts: sustainabilityThoughts ?? this.sustainabilityThoughts,
      lastResetMonth: lastResetMonth ?? this.lastResetMonth,
      lastResetYear: lastResetYear ?? this.lastResetYear,
    );
  }
}
