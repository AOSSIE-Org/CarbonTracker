import 'dart:io';

import 'package:carbon_tracker/features/fitness/screens/main_screen.dart';
import 'package:carbon_tracker/features/onboarding/providers/matchmaking_provider.dart';
import 'package:carbon_tracker/features/onboarding/providers/permissions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:carbon_tracker/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new user can complete onboarding', (tester) async {
    // 1. Launch the app with fake permission steps
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchmakingRunnerProvider.overrideWithValue(() async => 'proceed'),
          healthPermissionProvider.overrideWithValue(() async => true),
        ],
        child: const MyApp(),
      ),
    );

    // 2. Splash -> Onboarding
    await _pumpUntilFound(tester, find.text('Get Started'));
    expect(find.text('CarbonTracker'), findsOneWidget);

    // 3. Onboarding -> UserInfo
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('About You'), findsOneWidget);

    // 4. Continue must start disabled
    final continueFinder = find.widgetWithText(ElevatedButton, 'Continue');
    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      continueFinder,
      200,
      scrollable: scrollable,
    );
    expect(tester.widget<ElevatedButton>(continueFinder).onPressed, isNull);

    // 5. Fill the form
    await tester.scrollUntilVisible(
      find.text('Walking'),
      -200,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Walking'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'Aneesa'); // name
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), '60'); // weight
    await tester.pumpAndSettle();

    // 6. Open the privacy policy (required to enable Continue)
    final privacy = find.text('Read our Privacy Policy (required)');
    await tester.scrollUntilVisible(privacy, 200, scrollable: scrollable);
    await tester.tap(privacy);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // 7. Continue should now be enabled
    await tester.scrollUntilVisible(
      continueFinder,
      200,
      scrollable: scrollable,
    );
    expect(tester.widget<ElevatedButton>(continueFinder).onPressed, isNotNull);

    // 8. Submit
    await tester.tap(continueFinder);

    // 9. Android only: dismiss the watch modal
    if (Platform.isAndroid) {
      await _pumpUntilFound(tester, find.text('Record Activities on the Go'));
      await tester.tap(find.text('Close'));
      await tester.pump();
    }

    // 10. Should land on the main screen
    await _pumpUntilFound(tester, find.byType(MainScreen));
    expect(find.text('Fitness'), findsOneWidget);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}
