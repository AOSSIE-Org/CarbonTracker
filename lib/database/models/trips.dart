import 'package:carbon_tracker/database/models/base_model.dart';

class Trip extends BaseModel {
  final DateTime date;
  final double distance;
  final String transportMode;
  final double carbonSaved;

  Trip({
    super.id,
    required this.date,
    required this.distance,
    required this.transportMode,
    required this.carbonSaved,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      distance: (map['distance'] as num).toDouble(),
      transportMode: map['transport_mode'],
      carbonSaved: map['carbon_saved'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'distance': distance,
      'transport_mode': transportMode,
      'carbon_saved': carbonSaved,
    };
  }
}
