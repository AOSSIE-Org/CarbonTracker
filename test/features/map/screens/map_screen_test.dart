import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/map/models/search_options.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/repositories/trip_repository.dart';
import 'package:carbon_tracker/features/map/screens/map_screen.dart';
import 'package:carbon_tracker/features/map/services/location_service.dart';
import 'package:carbon_tracker/features/map/widgets/location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

// Fake UserNotifier

class _TestUserNotifier extends UserNotifier {
  _TestUserNotifier(this._initialUser);

  final User? _initialUser;

  @override
  User? build() => _initialUser;
}

// Fake TripsNotifier

class _TestTripsNotifier extends TripsNotifier {
  @override
  List<Trip> build() {
    return [];
  }

  @override
  Future<List<Trip>> loadTrips() async {
    state = [];
    return state;
  }
}

// Fake MapService

class _FakeMapService extends MapService {
  @override
  Future<Map<String, dynamic>> isPermissionGranted() async {
    return {'status': true};
  }

  @override
  Future<Position> getCurrentPosition() async {
    return Position(
      latitude: 22.5726,
      longitude: 88.3639,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<SearchResult?> retrieveAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    return SearchResult(
      locationString: 'Kolkata',
      lat: latitude,
      lon: longitude,
    );
  }

  @override
  Future<SearchOptions> queryPlaces(
    String currentQuery,
    String destinationQuery,
  ) async {
    return SearchOptions(
      currentLocationResults: [
        SearchResult(locationString: 'Kolkata', lat: 22.5726, lon: 88.3639),
      ],
      destinationLocationResults: [
        SearchResult(locationString: 'Howrah', lat: 22.5958, lon: 88.2636),
      ],
    );
  }

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

// Fake TripRepository

class _FakeTripRepository extends TripRepository {
  bool startTripCalled = false;
  bool cancelTripCalled = false;

  Trip? startedTrip;
  int? cancelledTripId;

  @override
  Future<int> startTrip(Trip trip) async {
    startTripCalled = true;
    startedTrip = trip;

    // Fake database ID.
    return 123;
  }

  @override
  Future<void> cancelTrip(int id) async {
    cancelTripCalled = true;
    cancelledTripId = id;
  }
}

Widget fakeMapUiBuilder({
  required double currentLat,
  required double currentLon,
  required double destinationLat,
  required double destinationLon,
  required RoadType type,
}) {
  return Text(
    'map:$currentLat,$currentLon->$destinationLat,$destinationLon:$type',
  );
}

// Tests

void main() {
  // Fake user

  final fakeUser = User(
    name: 'Test User',
    preferredTransports: [],
    frequentTransports: [],
    weight: 60,
    comparisonMode: ComparisonTransportMode.car,
    lastResetMonth: 9,
    lastResetYear: 2026,
  );

  // Helper for building the widget

  Widget buildTestable({
    List<Override> overrides = const [],
    MapService? mapService,
    TripRepository? tripRepository,
    bool isActive = true,
    MapUiBuilder? mapUiBuilder,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: MapScreen(
          isActive: isActive,
          mapOb: mapService ?? _FakeMapService(),
          tripRepo: tripRepository,
          mapUiBuilder: mapUiBuilder ?? fakeMapUiBuilder,
        ),
      ),
    );
  }

  // Basic rendering tests

  group('MapScreen rendering', () {
    testWidgets('shows a fallback message when there is no user data', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(null)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User data not available'), findsOneWidget);
    });

    testWidgets('renders the location search UI when a user exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          mapService: _FakeMapService(),
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User data not available'), findsNothing);

      expect(find.byType(TextField), findsWidgets);
    });
  });

  // Location tests

  group('MapScreen location', () {
    testWidgets('gets and displays the current location', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          mapService: _FakeMapService(),
          isActive: false,
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestable(
          mapService: _FakeMapService(),
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // The fake MapService returns "Kolkata".
      expect(find.text('Kolkata'), findsOneWidget);
    });

    testWidgets('shows destination search result', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          mapService: _FakeMapService(),
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      expect(textFields, findsWidgets);

      // LocationCard has two TextFields:
      //
      // 1. Current Location
      // 2. Destination
      //
      // The destination field is the second one.
      await tester.enterText(textFields.at(1), 'Howrah');

      await tester.pumpAndSettle();

      expect(find.text('Howrah'), findsOneWidget);
    });

    testWidgets('selects a destination from the search results', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          mapService: _FakeMapService(),
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(1), 'Howrah');

      await tester.pumpAndSettle();

      // Select the fake destination result.
      await tester.tap(find.text('Howrah'));

      await tester.pumpAndSettle();

      expect(find.text('Howrah'), findsOneWidget);
    });
  });

  // Start trip test

  group('MapScreen trip creation', () {
    testWidgets('starts a trip using the injected TripRepository', (
      tester,
    ) async {
      final fakeTripRepository = _FakeTripRepository();

      await tester.pumpWidget(
        buildTestable(
          isActive: false,
          mapService: _FakeMapService(),
          tripRepository: fakeTripRepository,
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestable(
          isActive: true,
          mapService: _FakeMapService(),
          tripRepository: fakeTripRepository,
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // 1. Enter destination

      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(1), 'Howrah');

      await tester.pumpAndSettle();

      // 2. Press the LocateButton

      final locateButton = find.byType(LocateButton);

      expect(locateButton, findsOneWidget);

      await tester.tap(locateButton);

      await tester.pumpAndSettle();

      // 3. Select current location

      expect(find.text('Kolkata'), findsNWidgets(2));

      await tester.tap(find.text('Kolkata').last);

      await tester.pumpAndSettle();

      // 4. Select destination

      expect(find.text('Howrah'), findsNWidgets(2));

      await tester.tap(find.text('Howrah').last);

      await tester.pumpAndSettle();

      // 5. Transport modes should now appear

      final walkingButton = find.text('walk');

      expect(walkingButton, findsOneWidget);

      await tester.tap(walkingButton);

      await tester.pumpAndSettle();

      // 6. Continue to route should now appear

      final continueButton = find.text('Continue to route');

      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);

      await tester.pumpAndSettle();

      // 7. Verify the repository received the trip

      expect(fakeTripRepository.startTripCalled, isTrue);
      expect(fakeTripRepository.startedTrip, isNotNull);
      expect(fakeTripRepository.startedTrip!.distance, 5.0);
      expect(fakeTripRepository.startedTrip!.transportMode, isNotEmpty);
      await tester.pumpAndSettle();

      // 8. Verify repository
      expect(fakeTripRepository.startTripCalled, isTrue);
      expect(fakeTripRepository.startedTrip, isNotNull);
      expect(fakeTripRepository.startedTrip!.distance, 5.0);
      expect(fakeTripRepository.startedTrip!.transportMode, isNotEmpty);

      // 4. Verify TripRepository received the trip

      expect(find.textContaining('map:'), findsOneWidget);

      expect(fakeTripRepository.startTripCalled, isTrue);

      expect(fakeTripRepository.startedTrip, isNotNull);

      expect(fakeTripRepository.startedTrip!.distance, 5.0);

      expect(fakeTripRepository.startedTrip!.transportMode, isNotEmpty);
    });
  });

  // Trip cancellation

  group('MapScreen trip cancellation', () {
    testWidgets('builds with an injected TripRepository', (tester) async {
      final fakeTripRepository = _FakeTripRepository();

      await tester.pumpWidget(
        buildTestable(
          mapService: _FakeMapService(),
          tripRepository: fakeTripRepository,
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User data not available'), findsNothing);
    });
  });
}
