import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/core/data/tracking_options.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/profile/data/trips_delete_modal_data.dart';
import 'package:carbon_tracker/features/profile/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeUserNotifier extends UserNotifier {
  FakeUserNotifier(this._initialUser);

  final User? _initialUser;

  User? lastUpdatedUser;
  bool deleteUserCalled = false;

  @override
  User? build() => _initialUser;

  @override
  Future<void> updateUser(User user) async {
    lastUpdatedUser = user;
    state = user;
  }

  @override
  Future<void> deleteUser() async {
    deleteUserCalled = true;
    state = null;
  }
}

// Fake TripsNotifier

class FakeTripsNotifier extends TripsNotifier {
  bool deleteTripsCalled = false;

  @override
  List<Trip> build() => [];

  @override
  Future<void> deleteTrips() async {
    deleteTripsCalled = true;
    state = [];
  }
}

Widget buildTestable({
  required User? user,
  FakeUserNotifier? userNotifier,
  FakeTripsNotifier? tripsNotifier,
}) {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) =>
            const Scaffold(body: Text('Onboarding Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userProvider.overrideWith(() => userNotifier ?? FakeUserNotifier(user)),
      tripProvider.overrideWith(() => tripsNotifier ?? FakeTripsNotifier()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  final fakeUser = User(
    name: 'Test User',
    preferredTransports: ['Walking'],
    frequentTransports: [],
    weight: 65,
    sustainabilityThoughts: 'take care of the environment',
    comparisonMode: ComparisonTransportMode.car,
    lastResetMonth: 9,
    lastResetYear: 2026,
  );

  group('ProfileScreen with no user', () {
    testWidgets('shows a loading indicator instead of the preferences card', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestable(user: null));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ProfileScreen with a user', () {
    testWidgets('renders the profile header and preference fields', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestable(user: fakeUser));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('65.0'), findsOneWidget); // weight field
      expect(
        find.text('take care of the environment'),
        findsOneWidget,
      ); // sustainability
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Cycling'), findsOneWidget);
    });

    testWidgets('toggling a transport chip updates the preferred transports', (
      tester,
    ) async {
      final fakeUserNotifier = FakeUserNotifier(fakeUser);

      await tester.pumpWidget(
        buildTestable(user: fakeUser, userNotifier: fakeUserNotifier),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cycling'));
      await tester.pumpAndSettle();

      expect(
        fakeUserNotifier.lastUpdatedUser?.preferredTransports,
        contains('Cycling'),
      );
    });

    testWidgets('selecting a tracking mode updates the tracking mode', (
      tester,
    ) async {
      final fakeUserNotifier = FakeUserNotifier(fakeUser);

      await tester.pumpWidget(
        buildTestable(user: fakeUser, userNotifier: fakeUserNotifier),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      expect(
        fakeUserNotifier.lastUpdatedUser?.trackingMode,
        TrackingOption.high.name,
      );
    });

    testWidgets('selecting a comparison mode updates the comparison mode', (
      tester,
    ) async {
      final fakeUserNotifier = FakeUserNotifier(fakeUser);

      await tester.pumpWidget(
        buildTestable(user: fakeUser, userNotifier: fakeUserNotifier),
      );
      await tester.pumpAndSettle();

      final busTile = find.byKey(const Key('Comparison-Bus'));

      expect(busTile, findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );

      await tester.tap(busTile);

      await tester.pumpAndSettle();

      expect(
        fakeUserNotifier.lastUpdatedUser?.comparisonMode,
        ComparisonTransportMode.bus,
      );
    });

    testWidgets('tapping SAVE CHANGES saves the edited weight', (tester) async {
      final fakeUserNotifier = FakeUserNotifier(fakeUser);

      await tester.pumpWidget(
        buildTestable(user: fakeUser, userNotifier: fakeUserNotifier),
      );
      await tester.pumpAndSettle();

      // The weight field is the first TextField; sustainability is the
      // second.
      await tester.enterText(find.byType(TextField).first, '70');

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );

      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(fakeUserNotifier.lastUpdatedUser?.weight, 70.0);
    });

    testWidgets('tapping SIGN OUT clears data and navigates to onboarding', (
      tester,
    ) async {
      final fakeUserNotifier = FakeUserNotifier(fakeUser);
      final fakeTripsNotifier = FakeTripsNotifier();

      await tester.pumpWidget(
        buildTestable(
          user: fakeUser,
          userNotifier: fakeUserNotifier,
          tripsNotifier: fakeTripsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );

      await tester.tap(find.text('SIGN OUT'));
      await tester.pumpAndSettle();

      expect(fakeUserNotifier.deleteUserCalled, isTrue);
      expect(fakeTripsNotifier.deleteTripsCalled, isTrue);
      expect(find.text('Onboarding Screen'), findsOneWidget);
    });
  });

  group('ProfileScreen My Data section', () {
    testWidgets('expands to show export and clear-trips options', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestable(user: fakeUser));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );

      expect(find.text('Export Data'), findsNothing);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Clear Stored Trips'), findsOneWidget);
    });

    testWidgets(
      'Clear Stored Trips opens a confirmation and Continue deletes trips',
      (tester) async {
        final fakeTripsNotifier = FakeTripsNotifier();

        await tester.pumpWidget(
          buildTestable(user: fakeUser, tripsNotifier: fakeTripsNotifier),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
        );

        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear Stored Trips'));
        await tester.pumpAndSettle();

        expect(
          find.text(TripsDeleteDialogStrings.clearTripHistoryTitle),
          findsOneWidget,
        );
        expect(
          find.text(TripsDeleteDialogStrings.clearTripHistoryContent),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(TextButton, 'Continue'));
        await tester.pumpAndSettle();

        expect(fakeTripsNotifier.deleteTripsCalled, isTrue);
        expect(
          find.text(TripsDeleteDialogStrings.clearTripHistoryTitle),
          findsNothing,
        );
      },
    );
  });
}
