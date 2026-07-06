import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripProvider = NotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);

class TripsNotifier extends Notifier<List<Trip>> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  List<Trip> build() => [];

  Future<List<Trip>> loadTrips() async {
    try {
      if (state.isEmpty) {
        await _databaseHelper.initializeTrips();
      }
      state = await _databaseHelper.queryAllTrips();
      return state;
    } catch (e) {
      debugPrint("Error loading trips: $e");
      return [];
    }
  }
}
