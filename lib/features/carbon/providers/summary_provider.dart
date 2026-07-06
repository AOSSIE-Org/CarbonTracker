import 'package:carbon_tracker/database/models/trips.dart';
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
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6)); // Sunday

    for (Trip trip in trips) {
      if (trip.date.isBefore(startOfWeek) || trip.date.isAfter(endOfWeek)) {
        // Skip trips not in the current week
        continue;
      }

      if (trip.date.year == now.year &&
          trip.date.month == now.month &&
          trip.date.day == now.day) {
        todayCarbonEmitted += trip.carbonEmitted;
      }

      // 1 for Monday, 7 for Sunday
      String dayOfWeek = days[trip.date.weekday - 1];
      totalCarbonSaved += trip.carbonSaved;
      totalCarbonEmitted += trip.carbonEmitted;
      weeklyData[dayOfWeek] = WeeklyData(
        carbonEmitted:
            (weeklyData[dayOfWeek]?.carbonEmitted ?? 0) + trip.carbonEmitted,
        carbonSaved:
            (weeklyData[dayOfWeek]?.carbonSaved ?? 0) + trip.carbonSaved,
      );
    }

    // 2. Create a Summary object

    Summary summary = Summary(
      totalCarbonEmitted: totalCarbonEmitted / 1000,
      totalCarbonSaved: totalCarbonSaved / 1000,
      todayCarbonEmitted: todayCarbonEmitted / 1000,
      summaryData: weeklyData,
    );

    // 4. Assign it to state

    debugPrint('Summary updated: ${summary.summaryData}');

    state = summary;
  }
}
