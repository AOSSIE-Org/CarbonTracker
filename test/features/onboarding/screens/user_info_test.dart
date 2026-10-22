import 'package:carbon_tracker/core/config/route_constants.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:carbon_tracker/features/fitness/providers/health_permission_provider.dart';
import 'package:carbon_tracker/features/fitness/screens/fitness_metrics_screen.dart';
import 'package:carbon_tracker/features/fitness/services/health_permission_service.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:carbon_tracker/features/fitness/widgets/health_permission_banner.dart';
import 'package:carbon_tracker/features/onboarding/screens/user_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';

class _FakeHealthPermissionService implements IHealthPermissionService {
  _FakeHealthPermissionService(this.statusResult);

  HealthPermissionResult statusResult;
  bool requestCalled = false;
  bool openPlayStoreCalled = false;
  bool openSettingsCalled = false;

  @override
  Future<HealthPermissionResult> requestPermissions() async {
    requestCalled = true;
    return statusResult;
  }

  @override
  Future<HealthPermissionResult> getPermissionStatus() async => statusResult;

  @override
  Future<bool> openSettings() async {
    openSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> openHealthConnectPlayStore() async {
    openPlayStoreCalled = true;
    return true;
  }
}

class _FakeHealthService implements IHealthService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasGrantedPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<int> getTodaySteps() async => 5000;

  @override
  Future<List<HealthDataPoint>> getHealthData() async => [];

  @override
  Future<List<StatCardData>> generateData() async => [];
}

class _FakeUserNotifier extends UserNotifier {
  User? _user;

  @override
  User? build() => _user;

  @override
  Future<void> saveUser(User user) async {
    _user = user;
    state = user;
  }
}

Future<void> _fillFormAndContinue(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;

  // Select a transport
  final transportFinder = find.text('Walking');
  await tester.scrollUntilVisible(transportFinder, 100, scrollable: scrollable);
  await tester.tap(transportFinder);
  await tester.pumpAndSettle();

  // Enter Name
  final textFields = find.byType(TextField);
  await tester.ensureVisible(textFields.at(0));
  await tester.enterText(textFields.at(0), 'Aneesa');
  await tester.pumpAndSettle();

  // Enter Weight
  await tester.ensureVisible(textFields.at(1));
  await tester.enterText(textFields.at(1), '65');
  await tester.pumpAndSettle();

  // Tap Privacy policy to set _readPrivacyPolicy = true
  final privacyFinder = find.text('Read our Privacy Policy (required)');
  await tester.scrollUntilVisible(privacyFinder, 100, scrollable: scrollable);
  await tester.tap(privacyFinder);
  await tester.pumpAndSettle();

  // Close the privacy modal
  final closeFinder = find.widgetWithText(TextButton, 'Close');
  if (closeFinder.evaluate().isNotEmpty) {
    await tester.tap(closeFinder);
    await tester.pumpAndSettle();
  }

  // Scroll to Continue button and tap it
  final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
  final mainScrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    continueButton,
    200,
    scrollable: mainScrollable,
  );
  expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNotNull);

  await tester.tap(continueButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  // If the watch modal appeared (on Android when all permissions granted), dismiss it
  final watchModalHeader = find.text('Record Activities on the Go');
  if (watchModalHeader.evaluate().isNotEmpty) {
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();
  }

  // Settle any remaining animations or navigation transitions
  await tester.pump(const Duration(milliseconds: 500));
}

Widget _createTestApp({
  required _FakeHealthPermissionService permService,
  required _FakeUserNotifier userNotifier,
}) {
  final router = GoRouter(
    initialLocation: '/user-info',
    routes: [
      GoRoute(
        path: '/user-info',
        name: RouteNames.userInfo,
        builder: (context, state) => const UserInfoScreen(),
      ),
      GoRoute(
        path: '/main-screen',
        name: RouteNames.mainScreen,
        builder: (context, state) => const FitnessMetricsScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      healthPermissionServiceProvider.overrideWithValue(permService),
      healthServiceProvider.overrideWithValue(_FakeHealthService()),
      userProvider.overrideWith(() => userNotifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('UserInfoScreen health permission onboarding flows', () {
    testWidgets(
      'Android: all granted -> onboarding completes, navigates to mainScreen, no banner on home',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final permService = _FakeHealthPermissionService(
            const HealthPermissionResult(
              status: HealthPermissionStatus.granted,
            ),
          );
          final userNotifier = _FakeUserNotifier();

          await tester.pumpWidget(
            _createTestApp(
              permService: permService,
              userNotifier: userNotifier,
            ),
          );
          await tester.pumpAndSettle();

          await _fillFormAndContinue(tester);

          expect(permService.requestCalled, isTrue);
          // Onboarding completes: user is saved
          expect(userNotifier.state, isNotNull);
          expect(userNotifier.state?.name, 'Aneesa');

          // Navigated to main screen
          expect(find.byType(FitnessMetricsScreen), findsOneWidget);
          // Banner not shown since all permissions granted
          expect(find.byType(HealthPermissionBanner), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Android: partially granted -> warning shown, onboarding STILL completes, banner shown on home',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final permService = _FakeHealthPermissionService(
            const HealthPermissionResult(
              status: HealthPermissionStatus.partial,
              grantedPermissions: ['StepsRecord'],
            ),
          );
          final userNotifier = _FakeUserNotifier();

          await tester.pumpWidget(
            _createTestApp(
              permService: permService,
              userNotifier: userNotifier,
            ),
          );
          await tester.pumpAndSettle();

          await _fillFormAndContinue(tester);

          expect(permService.requestCalled, isTrue);
          // Onboarding completed despite partial permissions
          expect(userNotifier.state, isNotNull);

          // Warning SnackBar shown
          expect(
            find.text(
              'Health permission denied, please grant permission to get full functionality',
            ),
            findsOneWidget,
          );

          // Navigated to main screen and banner is shown
          expect(find.byType(FitnessMetricsScreen), findsOneWidget);
          expect(find.byType(HealthPermissionBanner), findsOneWidget);
          expect(find.text('Partial Health Permissions'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Android: denied -> warning shown, onboarding STILL completes, banner shown on home',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final permService = _FakeHealthPermissionService(
            const HealthPermissionResult(status: HealthPermissionStatus.denied),
          );
          final userNotifier = _FakeUserNotifier();

          await tester.pumpWidget(
            _createTestApp(
              permService: permService,
              userNotifier: userNotifier,
            ),
          );
          await tester.pumpAndSettle();

          await _fillFormAndContinue(tester);

          expect(permService.requestCalled, isTrue);
          // Onboarding completes despite denied permissions
          expect(userNotifier.state, isNotNull);

          // Warning SnackBar shown
          expect(
            find.text(
              'Health permission denied, please grant permission to get full functionality',
            ),
            findsOneWidget,
          );

          // Navigated to main screen and banner is shown
          expect(find.byType(FitnessMetricsScreen), findsOneWidget);
          expect(find.byType(HealthPermissionBanner), findsOneWidget);
          expect(find.text('Health Permission Denied'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Android: Health Connect unavailable -> install link shown, onboarding completes',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final permService = _FakeHealthPermissionService(
            const HealthPermissionResult(
              status: HealthPermissionStatus.unavailable,
              message: 'Health Connect is unavailable',
            ),
          );
          final userNotifier = _FakeUserNotifier();

          await tester.pumpWidget(
            _createTestApp(
              permService: permService,
              userNotifier: userNotifier,
            ),
          );
          await tester.pumpAndSettle();

          await _fillFormAndContinue(tester);

          expect(permService.requestCalled, isTrue);
          // Onboarding completes!
          expect(userNotifier.state, isNotNull);

          // Install action and warning shown in SnackBar
          expect(
            find.text(
              'Health Connect is unavailable. Please install Health Connect to get full functionality.',
            ),
            findsOneWidget,
          );
          expect(
            find.widgetWithText(SnackBarAction, 'Install'),
            findsOneWidget,
          );

          // Navigated to main screen and install banner is shown
          expect(find.byType(FitnessMetricsScreen), findsOneWidget);
          expect(find.byType(HealthPermissionBanner), findsOneWidget);
          expect(find.text('Health Connect Not Installed'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('iOS: denied -> no early return, onboarding completes', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final permService = _FakeHealthPermissionService(
          const HealthPermissionResult(status: HealthPermissionStatus.denied),
        );
        final userNotifier = _FakeUserNotifier();

        await tester.pumpWidget(
          _createTestApp(permService: permService, userNotifier: userNotifier),
        );
        await tester.pumpAndSettle();

        await _fillFormAndContinue(tester);

        expect(permService.requestCalled, isTrue);
        // Onboarding completes: user saved and navigated
        expect(userNotifier.state, isNotNull);
        expect(userNotifier.state?.name, 'Aneesa');

        // Warning shown
        expect(
          find.text(
            'Health permission denied, please grant permission to get full functionality',
          ),
          findsOneWidget,
        );

        // Navigated to main screen
        expect(find.byType(FitnessMetricsScreen), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
