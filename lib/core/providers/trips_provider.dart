import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripProvider = NotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);

class TripsNotifier extends Notifier<List<Trip>> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  List<Trip> build() {
    Future.microtask(() => loadTrips());
    return [];
  }

  Future<List<Trip>> loadTrips() async {
    try {
      state = await _databaseHelper.queryAllTrips();
      debugPrint("Loaded trips: ${state.length}");
      return state;
    } catch (e) {
      debugPrint("Error loading trips: $e");
      return [];
    }
  }

  Future<void> deleteTrips() async {
    try {
      await _databaseHelper.clearTrips();
      state = [];
    } catch (e) {
      debugPrint("Error loading trips: $e");
    }
    loadTrips();
  }
}
