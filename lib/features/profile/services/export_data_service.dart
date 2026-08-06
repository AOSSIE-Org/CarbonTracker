import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ExportDataService {
  static Future<String> convertDataToJson() async {
    final List<Trip> trips = await DatabaseHelper().queryAllTrips();

    try {
      // Convert the list of trips to JSON
      final String jsonData = jsonEncode(
        trips.map((trip) {
          final t = trip.toMap();
          t['date'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(trip.date);
          return t;
        }).toList(),
      );

      return jsonData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<File> storeJsonToDir() async {
    try {
      final jsonData = await convertDataToJson();

      final directory = await getTemporaryDirectory();

      final logFile = File(
        '${directory.path}/trips_data-${DateTime.now().millisecondsSinceEpoch}.json',
      );

      final sink = logFile.openWrite();

      sink.write(jsonData);

      await sink.flush();
      await sink.close();

      return logFile;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> shareFile() async {
    File? file;
    try {
      file = await storeJsonToDir();
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      rethrow;
    } finally {
      if (file != null && await file.exists()) {
        await file.delete();
      }
    }
  }
}
