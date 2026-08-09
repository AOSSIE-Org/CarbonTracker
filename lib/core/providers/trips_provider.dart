import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripProvider = NotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);

class TripsNotifier extends Notifier<List<Trip>> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  int _generation = 0;
  @override
  List<Trip> build() {
    Future.microtask(() => loadTrips());
    return [];
  }

  Future<List<Trip>> loadTrips() async {
    final currentGeneration = _generation;
    try {
      final trips = await _databaseHelper.queryAllTrips();

      if (currentGeneration != _generation) {
        return state;
      }

      state = trips;
      return state;
    } catch (e) {
      debugPrint("Error loading trips: $e");
      return [];
    }
  }

  Future<void> deleteTrips() async {
    try {

      // Invalidate any load that started before the deletion.
      _generation++;

      await _databaseHelper.clearTrips();
      state = [];
    } catch (e) {
      debugPrint("Error loading trips: $e");
    }
  }
}
