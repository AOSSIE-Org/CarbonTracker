import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/trips.dart';

class TripRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> startTrip(Trip trip) {
    return _db.insert('trips', trip);
  }

  Future<void> cancelTrip(int id) {
    return _db.deleteData('trips', id);
  }
}
