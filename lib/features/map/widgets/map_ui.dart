import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapUI extends StatefulWidget {
  final double currentLat;
  final double currentLon;
  final double destinationLat;
  final double destinationLon;
  final RoadType type;

  const MapUI({
    super.key,
    required this.currentLat,
    required this.currentLon,
    required this.destinationLat,
    required this.destinationLon,
    required this.type,
  });

  @override
  State<MapUI> createState() => _MapUIState();
}

class _MapUIState extends State<MapUI> {
  late final _mapController = MapController(
    initPosition: GeoPoint(
      latitude: widget.currentLat,
      longitude: widget.currentLon,
    ),
  );

  String? _routeError;

  Future<void> drawRoad() async {
    final start = GeoPoint(
      latitude: widget.currentLat,
      longitude: widget.currentLon,
    );

    final destination = GeoPoint(
      latitude: widget.destinationLat,
      longitude: widget.destinationLon,
    );

    try {
      await _mapController.drawRoad(
        start,
        destination,
        roadType: widget.type,
        roadOption: const RoadOption(
          roadColor: Colors.blue,
          roadWidth: 8,
          zoomInto: true,
          roadBorderColor: Colors.black,
        ),
      );
    } catch (e) {
      debugPrint('Error drawing road: $e');
      setState(() {
        _routeError = 'Failed to draw route';
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_routeError != null) {
      return Center(
        child: Text(
          _routeError!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return OSMFlutter(
      controller: _mapController,
      onMapIsReady: (bool isReady) {
        if (isReady) {
          drawRoad();
        }
      },
      osmOption: const OSMOption(
        zoomOption: ZoomOption(
          initZoom: 15,
          minZoomLevel: 3,
          maxZoomLevel: 19,
          stepZoom: 1,
        ),
      ),
    );
  }
}
