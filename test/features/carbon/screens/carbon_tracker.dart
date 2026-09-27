import 'package:carbon_tracker/features/carbon/data/carbon_modal_data.dart';
import 'package:carbon_tracker/features/carbon/models/summary_model.dart';
import 'package:carbon_tracker/features/carbon/providers/summary_provider.dart';
import 'package:carbon_tracker/features/carbon/screens/carbon_tracker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake SummaryNotifier

class _FakeSummaryNotifier extends SummaryNotifier {
  _FakeSummaryNotifier(this._summary);

  final Summary? _summary;

  @override
  Summary? build() => _summary;
}

// Test helper

Widget buildTestable({required Summary? summary}) {
  return ProviderScope(
    overrides: [
      summaryProvider.overrideWith(() => _FakeSummaryNotifier(summary)),
    ],
    child: const MaterialApp(home: CarbonTrackerScreen()),
  );
}

void main() {
  group('CarbonTrackerScreen with no summary data', () {
    testWidgets('shows zero values and the chart empty state', (tester) async {
      await tester.pumpWidget(buildTestable(summary: null));
      await tester.pumpAndSettle();

      // "Carbon saved today" and the weekly stat card both fall back to 0.00.
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('0.00 kg'), findsOneWidget);
      expect(find.text('No data available'), findsOneWidget);
    });
  });

  group('CarbonTrackerScreen with summary data', () {
    final summary = Summary(
      totalCarbonSaved: 12.3,
      totalCarbonSavedToday: 1.5,
      summaryData: {'Mon': const WeeklyData(carbonSaved: 1.5)},
    );

    testWidgets('shows the values from the summary provider', (tester) async {
      await tester.pumpWidget(buildTestable(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('1.50'), findsOneWidget); // totalCarbonSavedToday
      expect(find.text('12.30 kg'), findsOneWidget); // totalCarbonSaved
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });
  });

  group('CarbonTrackerScreen info modal', () {
    testWidgets('opens the info modal when the info icon is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestable(summary: null));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byTooltip('More information about carbon footprint'),
      );
      await tester.pumpAndSettle();

      expect(find.text(carbonModalTitle), findsOneWidget);
      expect(find.text(carbonModalData), findsOneWidget);
    });

    testWidgets('closes the info modal when its close button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestable(summary: null));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byTooltip('More information about carbon footprint'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();

      expect(find.text(carbonModalTitle), findsNothing);
    });
  });
}
