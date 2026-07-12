import 'package:carbon_tracker/features/map/modals/search_results.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nominatim_flutter/model/request/request.dart';
import 'package:nominatim_flutter/model/response/nominatim_response.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';

class MapService {
  // Determine the current position of the device.
  static bool _configured = false;

  MapService._();

  static Future<bool> isPermissionGranted() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  static Future<Position> getCurrentPosition() async {
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

  static void configure() {
    if (_configured) return;

    // Configure Nominatim settings
    NominatimFlutter.instance.configureNominatim(
      useCacheInterceptor: true,
      maxStale: Duration(days: 7),
      baseUrl: 'https://your-nominatim-server.com',
      userAgent: 'CarbonTracker/1.0 (org.aossie.carbontracker)',
      printOnSuccess: true,
      convertFormData: true,
    );

    _configured = true;
  }

  static Future<String> retrieveAddressFromCoordinates(
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

      return address;
    } catch (e) {
      debugPrint("Error retrieving address: $e");
      return "";
    }
  }

  static Future<List<NominatimResponse>> _makeSearch(String query) async {

    // Make a search request using Nominatim

    try {
      configure();
      var searchRequest = SearchRequest(
        query: query,
        addressDetails: true,
        limit: 3,
      );

      var searchResults = await NominatimFlutter.instance.search(
        searchRequest: searchRequest,
        language: 'en-US,en;q=0.5',
      );

      debugPrint(
        "Making search request $query : ${searchResults.length} results found",
      );

      return searchResults;
    } catch (e) {
      debugPrint("Error searching for places: $e");
      return [];
    }
  }

  static Future<SearchResult> queryPlaces(
    String currentQuery,
    String destinationQuery,
  ) async {

    // Query places based on the current and destination queries

    List<String?> currentLocations = [];
    List<String?> destinationLocations = [];

    try {
      if (currentQuery.isEmpty) {
        Position currentLocationCoordinates = await getCurrentPosition();
        String currentLocationAddress = await retrieveAddressFromCoordinates(
          currentLocationCoordinates.latitude,
          currentLocationCoordinates.longitude,
        );

        currentLocations = [currentLocationAddress];
      } else {
        currentLocations = (await _makeSearch(
          currentQuery,
        )).map((result) => result.displayName).toList();
      }

      destinationLocations = (await _makeSearch(
        destinationQuery,
      )).map((result) => result.displayName).toList();
    } catch (e) {
      debugPrint("Error searching for places: $e");
    }

    return SearchResult(
      currentLocations: currentLocations,
      destinationLocations: destinationLocations,
    );
  }
}
