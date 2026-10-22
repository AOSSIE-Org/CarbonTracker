import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/carbon/models/summary_model.dart';
import 'package:carbon_tracker/features/carbon/providers/summary_provider.dart';
import 'package:carbon_tracker/features/carbon/screens/carbon_tracker.dart';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:carbon_tracker/features/fitness/providers/health_permission_provider.dart';
import 'package:carbon_tracker/features/fitness/services/health_permission_service.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:carbon_tracker/features/map/models/search_options.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/screens/map_screen.dart';
import 'package:carbon_tracker/features/map/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';

class _DeniedHealthPermissionService implements IHealthPermissionService {
  @override
  Future<HealthPermissionResult> requestPermissions() async =>
      const HealthPermissionResult(status: HealthPermissionStatus.denied);

  @override
  Future<HealthPermissionResult> getPermissionStatus() async =>
      const HealthPermissionResult(status: HealthPermissionStatus.denied);

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<bool> openHealthConnectPlayStore() async => true;
}

class _DeniedHealthService implements IHealthService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasGrantedPermissions() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<int> getTodaySteps() async => 0;

  @override
  Future<List<HealthDataPoint>> getHealthData() async => [];

  @override
  Future<List<StatCardData>> generateData() async => [];
}

class _FakeSummaryNotifier extends SummaryNotifier {
  @override
  Summary? build() => Summary(
    totalCarbonSaved: 10.5,
    totalCarbonSavedToday: 2.1,
    summaryData: {'Mon': const WeeklyData(carbonSaved: 2.1)},
  );
}

class _FakeUserNotifier extends UserNotifier {
  @override
  User? build() => User(
    name: 'Zero Permissions User',
    preferredTransports: const ['Walking'],
    frequentTransports: const ['Walking'],
    weight: 68.0,
    comparisonMode: ComparisonTransportMode.car,
    lastResetMonth: 10,
    lastResetYear: 2026,
  );
}

class _FakeTripsNotifier extends TripsNotifier {
  @override
  List<Trip> build() => [];

  @override
  Future<List<Trip>> loadTrips() async => [];
}

class _FakeMapService extends MapService {
  @override
  Future<Map<String, dynamic>> isPermissionGranted() async => {'status': true};

  @override
  Future<Position> getCurrentPosition() async => Position(
    latitude: 37.7749,
    longitude: -122.4194,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<SearchResult?> retrieveAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async => SearchResult(
    locationString: 'San Francisco',
    lat: latitude,
    lon: longitude,
  );

  @override
  Future<SearchOptions> queryPlaces(
    String currentQuery,
    String destinationQuery,
  ) async => SearchOptions(
    currentLocationResults: [
      SearchResult(locationString: 'SF', lat: 37.7749, lon: -122.4194),
    ],
    destinationLocationResults: [
      SearchResult(locationString: 'Oakland', lat: 37.8044, lon: -122.2712),
    ],
  );

  @override
  double calculateDistanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return 5.0;
  }
}

Widget _fakeMapUiBuilder({
  required double currentLat,
  required double currentLon,
  required double destinationLat,
  required double destinationLon,
  required RoadType type,
}) {
  return Text(
    'FakeMap:$currentLat,$currentLon->$destinationLat,$destinationLon',
  );
}

void main() {
  group('Regression: screens work with zero health permissions', () {
    testWidgets(
      'CarbonTrackerScreen loads and displays carbon stats with zero health permissions',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              healthPermissionServiceProvider.overrideWithValue(
                _DeniedHealthPermissionService(),
              ),
              healthServiceProvider.overrideWithValue(_DeniedHealthService()),
              userProvider.overrideWith(() => _FakeUserNotifier()),
              summaryProvider.overrideWith(() => _FakeSummaryNotifier()),
            ],
            child: const MaterialApp(home: CarbonTrackerScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Screen loads successfully and displays carbon savings
        expect(find.text('CARBON SAVED TODAY'), findsOneWidget);
        expect(find.text('2.10'), findsOneWidget);
        expect(find.text('10.50 kg'), findsOneWidget);
      },
    );

    testWidgets(
      'MapScreen loads and renders search UI with zero health permissions',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              healthPermissionServiceProvider.overrideWithValue(
                _DeniedHealthPermissionService(),
              ),
              healthServiceProvider.overrideWithValue(_DeniedHealthService()),
              userProvider.overrideWith(() => _FakeUserNotifier()),
              tripProvider.overrideWith(() => _FakeTripsNotifier()),
            ],
            child: MaterialApp(
              home: MapScreen(
                isActive: true,
                mapOb: _FakeMapService(),
                mapUiBuilder: _fakeMapUiBuilder,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Map UI loads without requiring health permissions
        expect(find.text('Current Location'), findsOneWidget);
        expect(find.text('Destination'), findsOneWidget);
      },
    );
  });
}
