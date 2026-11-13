import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nominatim_flutter/model/request/request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';

class MapService {
  // Determine the current position of the device.
  static bool _configured = false;

  const MapService();

  Future<Map<String, dynamic>> isPermissionGranted() async {
    LocationPermission permission;

    // Test if location services are enabled.
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return {
        'status': false,
        'reason': 'service_disabled',
        'message': 'Location services are disabled.',
      };
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return {
          'status': false,
          'reason': 'permission_denied',
          'message': 'Location permissions are denied.',
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return {
        'status': false,
        'reason': 'permission_denied_forever',
        'message': 'Location permissions are permanently denied.',
      };
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return {'status': true};
  }

  Future<Position> getCurrentPosition() async {
    try {
      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      return position;
    } catch (e) {
      debugPrint("Error getting current position: $e");
      rethrow;
    }
  }

  void configure() {
    if (_configured) return;

    // Configure Nominatim settings
    NominatimFlutter.instance.configureNominatim(
      useCacheInterceptor: true,
      maxStale: Duration(days: 7),
      userAgent: 'CarbonTracker/1.0 (org.aossie.carbontracker)',
      printOnSuccess: true,
      convertFormData: true,
    );

    _configured = true;
  }

  Future<SearchResult?> retrieveAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // Retrieve the address from the coordinates using Nominatim

    try {
      configure();
      final reverseRequest = ReverseRequest(
        lat: latitude,
        lon: longitude,
        addressDetails: true,
      );
      final reverseResult = await NominatimFlutter.instance.reverse(
        reverseRequest: reverseRequest,
        language: 'en-US,en;q=0.5', // Specify the desired language(s) here
      );

      String? address = reverseResult.displayName;

      if (address == null || address.isEmpty) {
        throw Exception("Address not found.");
      }

      return SearchResult(
        locationString: address,
        lat: latitude,
        lon: longitude,
      );
    } catch (e) {
      debugPrint("Error retrieving address: $e");
      return null;
    }
  }

  Future<List<SearchResult>> searchPlace(String query, {int limit = 5}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      configure();
      final searchRequest = SearchRequest(
        query: trimmed,
        addressDetails: true,
        limit: limit,
      );

      final searchResults = await NominatimFlutter.instance.search(
        searchRequest: searchRequest,
        language: 'en-US,en;q=0.5',
      );

      return searchResults
          .where(
            (result) =>
                result.displayName != null &&
                result.displayName!.isNotEmpty &&
                result.lat != null &&
                result.lon != null &&
                double.tryParse(result.lat!) != null &&
                double.tryParse(result.lon!) != null,
          )
          .map(
            (result) => SearchResult(
              locationString: result.displayName!,
              lat: double.parse(result.lat!),
              lon: double.parse(result.lon!),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error searching places for '$trimmed': $e");
      return [];
    }
  }

  double calculateDistanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    return distanceInMeters / 1000;
  }
}
