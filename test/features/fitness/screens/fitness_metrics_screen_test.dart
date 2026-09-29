import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:carbon_tracker/features/fitness/widgets/stat_card.dart';
import 'package:carbon_tracker/features/fitness/screens/fitness_metrics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

class _FakeHealthService implements IHealthService {
  _FakeHealthService({
    bool permissionsGranted = true,
    List<StatCardData>? stats,
  }) : _permissionsGranted = permissionsGranted,
       _stats = stats ?? [];

  final bool _permissionsGranted;
  final List<StatCardData> _stats;
  int requestPermissionsCallCount = 0;
  int generateDataCallCount = 0;

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCallCount++;
    return _permissionsGranted;
  }

  @override
  Future<List<StatCardData>> generateData() async {
    generateDataCallCount++;
    return _stats;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasGrantedPermissions() async => _permissionsGranted;

  @override
  Future<int> getTodaySteps() async => 0;

  @override
  Future<List<HealthDataPoint>> getHealthData() async => [];
}

class _FakeUserNotifier extends UserNotifier {
  _FakeUserNotifier(this._initialUser);

  final User? _initialUser;

  @override
  User? build() => _initialUser;
}

User _fakeUser() => User(
  name: 'Aneesa',
  preferredTransports: const [],
  frequentTransports: const [],
  weight: 60.0,
  lastResetMonth: 1,
  lastResetYear: 2026,
);

List<StatCardData> _fakeStats(int count) => List.generate(
  count,
  (i) => StatCardData(
    icon: Icons.favorite,
    iconColor: Colors.red,
    iconBg: Colors.white,
    label: 'Stat $i',
    value: '$i',
  ),
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required User? user,
  required _FakeHealthService healthService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith(() => _FakeUserNotifier(user)),
        healthServiceProvider.overrideWithValue(healthService),
      ],
      child: const MaterialApp(home: FitnessMetricsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('FitnessMetricsScreen', () {
    testWidgets('no user: shows onboarding message, never calls health service', (
      tester,
    ) async {
      final health = _FakeHealthService();

      await _pumpScreen(tester, user: null, healthService: health);

      expect(
        find.text(
          'Onboarding not completed. Please complete onboarding to view fitness metrics.',
        ),
        findsOneWidget,
      );
      expect(health.requestPermissionsCallCount, 0);
      expect(health.generateDataCallCount, 0);
    });

    testWidgets('user present, permissions denied: shows fallback message, '
        'never fetches stats', (tester) async {
      final health = _FakeHealthService(permissionsGranted: false);

      await _pumpScreen(tester, user: _fakeUser(), healthService: health);

      expect(
        find.text(
          'No fitness metrics available. Please ensure you have granted the necessary permissions and have health data available.',
        ),
        findsOneWidget,
      );
      expect(health.generateDataCallCount, 0);
    });

    testWidgets('user present, permissions granted: renders one StatCard per '
        'returned stat', (tester) async {
      final health = _FakeHealthService(stats: _fakeStats(3));

      await _pumpScreen(tester, user: _fakeUser(), healthService: health);

      expect(find.byType(StatCard), findsNWidgets(3));
    });

    testWidgets('tapping refresh re-fetches stats', (tester) async {
      final health = _FakeHealthService(stats: _fakeStats(2));

      await _pumpScreen(tester, user: _fakeUser(), healthService: health);
      expect(health.generateDataCallCount, 1);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(health.generateDataCallCount, 2);
    });
  });
}
