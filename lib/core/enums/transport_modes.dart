import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

enum TransportModes { walk, run, bike }

RoadType getRoadType(TransportModes mode) {
  switch (mode) {
    case TransportModes.walk:
      return RoadType.foot;

    case TransportModes.run:
      return RoadType.foot;

    case TransportModes.bike:
      return RoadType.bike;
  }
}


