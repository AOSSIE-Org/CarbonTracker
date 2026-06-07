import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:carbon_tracker/database/database_exceptions.dart';
import 'package:carbon_tracker/database/models/base_model.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/database/models/user.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  // Initialize the database, creating tables if they don't exist

  Future<Database> initDB() async {
    String databasePath = await getDatabasesPath();
    String path = p.join(databasePath, 'carbon_tracker.db');

    try {
      Database db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE user (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            preferred_transports TEXT NOT NULL,
            frequent_transports TEXT NOT NULL,
            tracking_mode TEXT NOT NULL,
            weight REAL NOT NULL,
            sustainability_thoughts TEXT,
            last_reset_month INTEGER NOT NULL,
            last_reset_year INTEGER NOT NULL
          )
        ''');
          await db.execute('''
            CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date INTEGER NOT NULL,
            distance REAL NOT NULL,
            transport_mode TEXT NOT NULL,
            carbon_emitted REAL NOT NULL,
            carbon_saved REAL NOT NULL
          )
        ''');
        },
      );

      return db;
    } on DatabaseException catch (e) {
      throw AppDatabaseException(
        "Failed to initialize database: ${e.toString()}",
      );
    }
  }

  // Get the database instance, initializing it if necessary

  Future<Database> getDB() async {
    try {
      if (_database != null) return _database!;
      _database = await initDB();
      return _database!;
    } on AppDatabaseException {
      rethrow;
    } catch (e) {
      throw AppDatabaseException("Failed to get database: ${e.toString()}");
    }
  }

  // To close the database when the app is terminated

  // Note: In a typical Flutter app, you might not need to manually close the database, but it's good practice to provide a method for it.
  Future<void> closeDB() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
    } on DatabaseException catch (e) {
      throw AppDatabaseException("Failed to close database: ${e.toString()}");
    }
  }

  // CRUD operations (applying to both User and Trip models)

  Future<int> insert<T extends BaseModel>(String table, T obj) async {
    try {
      final Database db = await getDB();
      return await db.insert(table, obj.toMap());
    } on DatabaseException catch (e) {
      throw AppDatabaseException(
        "Failed to insert into $table: ${e.toString()}",
      );
    }
  }

  Future<int> updateData<T extends BaseModel>(String table, T obj) async {
    try {
      final Database db = await getDB();
      int count = await db.update(
        table,
        obj.toMap(),
        where: 'id = ?',
        whereArgs: [obj.id],
      );

      if (count == 0) {
        throw AppDatabaseException(
          "No record with ID ${obj.id} found in $table to update",
        );
      }
      return count;
    } on AppDatabaseException {
      rethrow;
    } on DatabaseException catch (e) {
      throw AppDatabaseException("Failed to update database ${e.toString()}");
    }
  }

  Future<int> deleteData(String table, int id) async {
    try {
      final Database db = await getDB();
      int count = await db.delete(table, where: 'id = ?', whereArgs: [id]);
      if (count == 0) {
        throw AppDatabaseException(
          "No record with ID $id found in $table to delete",
        );
      }
      return count;
    } on AppDatabaseException {
      rethrow;
    } on DatabaseException catch (e) {
      throw AppDatabaseException(
        "Failed to delete $id from $table: ${e.toString()}",
      );
    }
  }

  // Query the user data (since we have a single-user design, we can just return the first row)

  Future<User> queryUser() async {
    try {
      final Database db = await getDB();
      List<Map<String, dynamic>> results = await db.query("user");
      if (results.isEmpty) {
        throw AppDatabaseException("User not found");
      }
      return User.fromMap(results.first);
    } on AppDatabaseException {
      rethrow;
    } on DatabaseException catch (e) {
      throw AppDatabaseException("Failed to query user data: ${e.toString()}");
    }
  }

  // Query all trips for a specific user (not filtering by user since we have a single-user design)

  Future<List<Trip>> queryAllTrips() async {
    try {
      final Database db = await getDB();
      List<Map<String, dynamic>> tripMap = await db.query("trips");

      return tripMap.map((item) => Trip.fromMap(item)).toList();
    } on DatabaseException catch (e) {
      throw AppDatabaseException("Failed to query trips: ${e.toString()}");
    }
  }

  // Query a particular trip

  Future<Trip> getTripById(int id) async {
    try {
      final Database db = await getDB();
      List<Map<String, dynamic>> results = await db.query(
        "trips",
        where: 'id = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) {
        throw AppDatabaseException("Trip with ID $id not found");
      }

      return Trip.fromMap(results.first);
    } on AppDatabaseException {
      rethrow;
    } on DatabaseException catch (e) {
      throw AppDatabaseException("Failed to query database: ${e.toString()}");
    }
  }

  // To clear all trips (for testing purposes)

  Future<void> clearTrips() async {
    try {
      final Database db = await getDB();
      await db.delete("trips");
    } on DatabaseException catch (e) {
      throw AppDatabaseException("Failed to clear trips: ${e.toString()}");
    }
  }

  // To reset the database (for testing purposes)

  Future<void> resetDB() async {
    try {
      final Database db = await getDB();
      await db.delete("user");
      await db.delete("trips");
    } on DatabaseException catch (e) {
      throw AppDatabaseException("Failed to reset database: ${e.toString()}");
    }
  }

  // To initialize the database with some default user data (for testing purposes)

  Future<void> initializeUser() async {
    Map<String, dynamic> user = {
      'id': 1,
      'preferred_transports': '["car", "bus"]',
      'frequent_transports': '["car"]',
      'tracking_mode': 'refresh',
      'weight': 70.0,
      'sustainability_thoughts': "I want to reduce my carbon footprint!",
      'last_reset_month': DateTime.now().month,
      'last_reset_year': DateTime.now().year,
    };

    try {
      final Database db = await getDB();
      final result = await db.query('user', where: 'id = ?', whereArgs: [1]);

      if (result.isEmpty) {
        await db.insert("user", user);
      }
    } on DatabaseException catch (e) {
      throw AppDatabaseException(
        "Failed to initialize user data: ${e.toString()}",
      );
    }
  }

  // To initialize the database with some default trips data (for testing purposes)

  Future<void> initializeTrips() async {
    List<Map<String, dynamic>> trips = [];

    for (int i = 1; i <= 5; i++) {
      trips.add({
        'date': DateTime.now().millisecondsSinceEpoch,
        'distance': 10.0 * i,
        'transport_mode': i % 2 == 0 ? "car" : "bus",
        'carbon_emitted': 2.5 * i,
        'carbon_saved': 1.0 * i,
      });
    }

    try {
      final Database db = await getDB();
      await db.transaction((txn) async {
        for (Map<String, dynamic> trip in trips) {
          await txn.insert("trips", trip);
        }
      });
    } on DatabaseException catch (e) {
      throw AppDatabaseException(
        "Failed to initialize trips data: ${e.toString()}",
      );
    }
  }
}
