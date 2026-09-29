import 'package:carbon_tracker/core/enums/transport_modes.dart';

double calculateTime(double distanceKm, TransportModes mode) {
  double speed;

  switch (mode) {
    case TransportModes.walk:
      speed = 5.0; // km/h
      break;
    case TransportModes.run:
      speed = 8.0; // km/h
      break;
    case TransportModes.bike:
      speed = 15.0; // km/h
      break;
  }

  return (distanceKm / speed) * 60;
}
