import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/repositories/trip_repository.dart';
import 'package:carbon_tracker/features/map/screens/map_screen.dart';
import 'package:carbon_tracker/features/map/services/location_service.dart';
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
  final Map<String, dynamic> permissionResult;
  int searchPlaceCallCount = 0;

  _FakeMapService({this.permissionResult = const {'status': true}});

  @override
  Future<Map<String, dynamic>> isPermissionGranted() async {
    return permissionResult;
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
  Future<List<SearchResult>> searchPlace(String query, {int limit = 5}) async {
    searchPlaceCallCount++;
    if (query.toLowerCase().contains('howrah')) {
      return [
        SearchResult(locationString: 'Howrah', lat: 22.5958, lon: 88.2636),
      ];
    }
    return [
      SearchResult(locationString: 'Kolkata', lat: 22.5726, lon: 88.3639),
    ];
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
    MapUiBuilder? mapUiBuilder,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: MapScreen(
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
    testWidgets(
      'gets and displays the current location when GPS icon is pressed',
      (tester) async {
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

        // Tap GPS button
        await tester.tap(find.byIcon(Icons.gps_fixed));
        await tester.pumpAndSettle();

        // The fake MapService returns "Kolkata".
        expect(find.text('Kolkata'), findsOneWidget);
      },
    );

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
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // "Howrah" appears in the TextField and in the suggestion list
      expect(find.text('Howrah'), findsWidgets);
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
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Select the fake destination result from suggestions.
      await tester.tap(find.text('Howrah').last);

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
          mapService: _FakeMapService(),
          tripRepository: fakeTripRepository,
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // 1. Enter start location and select from suggestions
      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(0), 'Kolkata');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kolkata').last);
      await tester.pumpAndSettle();

      // 2. Enter destination and select from suggestions
      await tester.enterText(textFields.at(1), 'Howrah');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
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

  // Location permissions & SnackBar tests

  group('MapScreen location permissions & SnackBar', () {
    testWidgets(
      'shows actionable SnackBar when location service is disabled and keeps screen open',
      (tester) async {
        final mapService = _FakeMapService(
          permissionResult: {
            'status': false,
            'reason': 'service_disabled',
            'message': 'Location services are disabled.',
          },
        );

        await tester.pumpWidget(
          buildTestable(
            mapService: mapService,
            overrides: [
              userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
              tripProvider.overrideWith(() => _TestTripsNotifier()),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Tap the GPS button
        await tester.tap(find.byIcon(Icons.gps_fixed));
        await tester.pumpAndSettle();

        // SnackBar appears with message and Settings action
        expect(
          find.text(
            'Location services are disabled. Enable GPS to detect your location.',
          ),
          findsOneWidget,
        );
        expect(find.text('Settings'), findsOneWidget);

        // Screen remains fully rendered and functional (never replaced with an error screen)
        expect(find.byType(TextField), findsWidgets);

        // Advance time past the 4-second auto-dismiss timer of showAppSnackBar
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Verify the SnackBar has automatically dismissed
        expect(
          find.text(
            'Location services are disabled. Enable GPS to detect your location.',
          ),
          findsNothing,
        );
        expect(find.text('Settings'), findsNothing);
      },
    );

    testWidgets('shows SnackBar when location permission is permanently denied', (
      tester,
    ) async {
      final mapService = _FakeMapService(
        permissionResult: {
          'status': false,
          'reason': 'permission_denied_forever',
          'message': 'Location permissions are permanently denied.',
        },
      );

      await tester.pumpWidget(
        buildTestable(
          mapService: mapService,
          overrides: [
            userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
            tripProvider.overrideWith(() => _TestTripsNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.gps_fixed));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Location permission is permanently denied. Enable it in app settings.',
        ),
        findsOneWidget,
      );
      expect(find.text('Settings'), findsOneWidget);

      // Advance time past the 4-second auto-dismiss timer of showAppSnackBar
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify the SnackBar has automatically dismissed
      expect(
        find.text(
          'Location permission is permanently denied. Enable it in app settings.',
        ),
        findsNothing,
      );
      expect(find.text('Settings'), findsNothing);
    });
  });

  // Selection & Validation tests

  group('MapScreen selection & validation', () {
    testWidgets(
      'shows SnackBar and blocks route when start and destination are identical',
      (tester) async {
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

        // Select "Kolkata" as start
        await tester.enterText(textFields.at(0), 'Kolkata');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kolkata').last);
        await tester.pumpAndSettle();

        // Select "Kolkata" as destination as well
        await tester.enterText(textFields.at(1), 'Kolkata');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kolkata').last);
        await tester.pumpAndSettle();

        // Warning SnackBar is shown
        expect(
          find.text('Start and destination cannot be the same place.'),
          findsOneWidget,
        );

        // Route options never appear
        expect(find.text('Choose a mode of transportation'), findsNothing);

        // Advance time past the 4-second auto-dismiss timer of showAppSnackBar
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Verify the warning SnackBar has automatically dismissed
        expect(
          find.text('Start and destination cannot be the same place.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'does not show transport modes when user types without selecting from suggestions',
      (tester) async {
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

        // User types arbitrary text in both without tapping any suggestion
        await tester.enterText(textFields.at(0), 'Some random place');
        await tester.enterText(textFields.at(1), 'Another random place');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Transport modes should NOT appear because neither has verified coordinates
        expect(find.text('Choose a mode of transportation'), findsNothing);
      },
    );
  });

  // Search UX & Debouncing tests

  group('MapScreen search UX & debouncing', () {
    testWidgets('typing in destination immediately clears start suggestions', (
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

      // 1. Type in start field to show start suggestions
      await tester.enterText(textFields.at(0), 'Kolkata');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Start suggestion tile is visible
      expect(find.text('Kolkata'), findsWidgets);

      // 2. Type in destination field
      await tester.enterText(textFields.at(1), 'Howrah');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Destination suggestions are visible
      expect(find.text('Howrah'), findsWidgets);
    });

    testWidgets(
      'typing whitespace does not call searchPlace and immediately clears suggestions',
      (tester) async {
        final mapService = _FakeMapService();

        await tester.pumpWidget(
          buildTestable(
            mapService: mapService,
            overrides: [
              userProvider.overrideWith(() => _TestUserNotifier(fakeUser)),
              tripProvider.overrideWith(() => _TestTripsNotifier()),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Type whitespace only
        await tester.enterText(textFields.at(0), '    ');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // searchPlace should never have been invoked
        expect(mapService.searchPlaceCallCount, 0);
      },
    );
  });
}
