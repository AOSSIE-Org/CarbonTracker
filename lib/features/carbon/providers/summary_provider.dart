import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/features/carbon/constants/weekday_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carbon_tracker/features/carbon/models/summary_model.dart';

final summaryProvider = NotifierProvider<SummaryNotifier, Summary?>(
  SummaryNotifier.new,
);

class SummaryNotifier extends Notifier<Summary?> {
  @override
  Summary? build() => null;

  void setSummary(Summary summary) {
    state = summary;
  }

  Summary? getSummary() {
    return state;
  }

  Future<void> loadSummary(List<Trip> trips) async {
    // 1. Calculate weekly totals

    double totalCarbonEmitted = 0.0;
    double totalCarbonSaved = 0.0;
    double todayCarbonEmitted = 0.0;
    Map<String, WeeklyData> weeklyData = {};
    List<String> days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

    DateTime now = DateTime.now();

    DateTime startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    ); // Monday
    DateTime startOfNextWeek = startOfWeek.add(Duration(days: 7));

    for (Trip trip in trips) {
      if (trip.date.isBefore(startOfWeek) ||
          !trip.date.isBefore(startOfNextWeek)) {
        // Skip trips not in the current week
        continue;
      }

      final dayOfWeek = WeekdayConstants.days[trip.date.weekday - 1];
      final emittedKg = trip.carbonEmitted / 1000;
      final savedKg = trip.carbonSaved / 1000;

      if (trip.date.year == now.year &&
          trip.date.month == now.month &&
          trip.date.day == now.day) {
        todayCarbonEmitted += emittedKg;
      }

      totalCarbonEmitted += emittedKg;
      totalCarbonSaved += savedKg;

      weeklyData[dayOfWeek] = WeeklyData(
        carbonEmitted: (weeklyData[dayOfWeek]?.carbonEmitted ?? 0) + emittedKg,
        carbonSaved: (weeklyData[dayOfWeek]?.carbonSaved ?? 0) + savedKg,
      );
    }

    // 2. Create a Summary object

    Summary summary = Summary(
      totalCarbonEmitted: totalCarbonEmitted,
      totalCarbonSaved: totalCarbonSaved,
      todayCarbonEmitted: todayCarbonEmitted,
      summaryData: weeklyData,
    );

    // 4. Assign it to state

    debugPrint('Summary updated: ${summary.summaryData}');

    state = summary;
  }
}
