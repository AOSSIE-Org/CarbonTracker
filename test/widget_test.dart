import 'package:carbon_tracker/core/config/route_constants.dart';
import 'package:carbon_tracker/features/onboarding/screens/onboarding.dart';
import 'package:carbon_tracker/generated/app_localizations.dart';
import 'package:carbon_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('MyApp wires AppLocalizations into MaterialApp.router', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      materialApp.localizationsDelegates,
      contains(AppLocalizations.delegate),
    );
    expect(materialApp.supportedLocales, AppLocalizations.supportedLocales);
  });

  testWidgets('onboarding welcome screen shows CarbonTracker branding', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RoutePaths.onboarding,
      routes: [
        GoRoute(
          path: RoutePaths.onboarding,
          name: RouteNames.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: RoutePaths.userInfo,
          name: RouteNames.userInfo,
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CarbonTracker'), findsOneWidget);
    expect(
      find.text('Eco-friendly fitness tracking for a\nbetter planet.'),
      findsOneWidget,
    );
    expect(find.text('Get Started'), findsOneWidget);

    final context = tester.element(find.text('CarbonTracker'));
    expect(AppLocalizations.of(context), isNotNull);
  });
}
