import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:carbon_tracker/features/fitness/providers/health_permission_provider.dart';
import 'package:carbon_tracker/features/fitness/screens/fitness_metrics_screen.dart';
import 'package:carbon_tracker/features/fitness/services/health_permission_service.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:carbon_tracker/features/fitness/widgets/health_permission_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

class _FakeHealthPermissionService implements IHealthPermissionService {
  _FakeHealthPermissionService(this.statusResult);

  HealthPermissionResult statusResult;
  int requestPermissionsCallCount = 0;
  int getPermissionStatusCallCount = 0;
  int openPlayStoreCallCount = 0;
  int openSettingsCallCount = 0;

  @override
  Future<HealthPermissionResult> requestPermissions() async {
    requestPermissionsCallCount++;
    return statusResult;
  }

  @override
  Future<HealthPermissionResult> getPermissionStatus() async {
    getPermissionStatusCallCount++;
    return statusResult;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCallCount++;
    return true;
  }

  @override
  Future<bool> openHealthConnectPlayStore() async {
    openPlayStoreCallCount++;
    return true;
  }
}

class _FakeHealthService implements IHealthService {
  _FakeHealthService({this.permissionsGranted = true});

  bool permissionsGranted;
  int generateDataCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasGrantedPermissions() async => permissionsGranted;

  @override
  Future<bool> requestPermissions() async => permissionsGranted;

  @override
  Future<int> getTodaySteps() async => 1000;

  @override
  Future<List<HealthDataPoint>> getHealthData() async => [];

  @override
  Future<List<StatCardData>> generateData() async {
    generateDataCallCount++;
    return [
      StatCardData(
        icon: Icons.directions_walk,
        iconColor: Colors.blue,
        iconBg: Colors.white,
        label: 'Steps',
        value: '1000',
      ),
    ];
  }
}

class _FakeUserNotifier extends UserNotifier {
  _FakeUserNotifier(this._user);

  final User? _user;

  @override
  User? build() => _user;
}

User _fakeUser() => User(
  name: 'Bhavik',
  preferredTransports: const ['Walking'],
  frequentTransports: const ['Walking'],
  weight: 70.0,
  lastResetMonth: 10,
  lastResetYear: 2026,
);

void main() {
  group('HealthPermissionBanner widget tests', () {
    testWidgets('renders properly for Health Connect unavailable', (
      tester,
    ) async {
      bool actionTapped = false;
      bool dismissTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HealthPermissionBanner(
              statusResult: const HealthPermissionResult(
                status: HealthPermissionStatus.unavailable,
              ),
              onAction: () => actionTapped = true,
              onDismiss: () => dismissTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Health Connect Not Installed'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Install Health Connect'),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Install Health Connect'),
      );
      expect(actionTapped, isTrue);

      await tester.tap(find.byKey(const Key('dismiss_permission_banner')));
      expect(dismissTapped, isTrue);
    });

    testWidgets('renders properly for partial health permissions', (
      tester,
    ) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HealthPermissionBanner(
              statusResult: const HealthPermissionResult(
                status: HealthPermissionStatus.partial,
                grantedPermissions: ['StepsRecord'],
              ),
              onAction: () => actionTapped = true,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Partial Health Permissions'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Grant Permission'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Grant Permission'));
      expect(actionTapped, isTrue);
    });

    testWidgets('renders properly for denied health permissions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HealthPermissionBanner(
              statusResult: const HealthPermissionResult(
                status: HealthPermissionStatus.denied,
              ),
              onAction: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Health Permission Denied'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Grant Permission'),
        findsOneWidget,
      );
    });
  });

  group('Home screen banner lifecycle & integration on FitnessMetricsScreen', () {
    testWidgets(
      'banner appears when denied, dismiss hides it, button triggers request',
      (tester) async {
        final permService = _FakeHealthPermissionService(
          const HealthPermissionResult(status: HealthPermissionStatus.denied),
        );
        final healthService = _FakeHealthService(permissionsGranted: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProvider.overrideWith(() => _FakeUserNotifier(_fakeUser())),
              healthPermissionServiceProvider.overrideWithValue(permService),
              healthServiceProvider.overrideWithValue(healthService),
            ],
            child: const MaterialApp(home: FitnessMetricsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Banner is shown because permissions are denied
        expect(find.byType(HealthPermissionBanner), findsOneWidget);
        expect(find.text('Health Permission Denied'), findsOneWidget);

        // Tapping action button triggers permission request
        await tester.tap(
          find.byKey(const Key('permission_banner_action_button')),
        );
        await tester.pumpAndSettle();
        expect(permService.requestPermissionsCallCount, 1);

        // Dismiss button hides banner
        await tester.tap(find.byKey(const Key('dismiss_permission_banner')));
        await tester.pumpAndSettle();
        expect(find.byType(HealthPermissionBanner), findsNothing);
      },
    );

    testWidgets(
      'state refreshes on app resume: banner disappears when permissions granted',
      (tester) async {
        final permService = _FakeHealthPermissionService(
          const HealthPermissionResult(status: HealthPermissionStatus.denied),
        );
        final healthService = _FakeHealthService(permissionsGranted: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProvider.overrideWith(() => _FakeUserNotifier(_fakeUser())),
              healthPermissionServiceProvider.overrideWithValue(permService),
              healthServiceProvider.overrideWithValue(healthService),
            ],
            child: const MaterialApp(home: FitnessMetricsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initially denied -> banner shown
        expect(find.byType(HealthPermissionBanner), findsOneWidget);

        // User went to settings and granted all permissions
        permService.statusResult = const HealthPermissionResult(
          status: HealthPermissionStatus.granted,
        );
        healthService.permissionsGranted = true;

        // Simulate app resuming from background / settings
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        // Banner should now be hidden
        expect(find.byType(HealthPermissionBanner), findsNothing);
        // Stats should be refreshed
        expect(healthService.generateDataCallCount, greaterThanOrEqualTo(1));
      },
    );
  });
}
