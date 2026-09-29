import 'dart:async';
import 'dart:convert';

import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WatchService {
  static const MethodChannel _platform = MethodChannel(
    'org.aossie.carbon_tracker/wear_connection',
  );

  static Completer<double?>? _heartRateCompleter;
  static Completer<void>? _exerciseDataCompleter;

  void initialize() {
    _platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    // Handle incoming method calls from the native side

    if (call.method == 'heartRateData') {
      final double? data = double.tryParse(call.arguments.toString());

      if (_heartRateCompleter != null && !_heartRateCompleter!.isCompleted) {
        _heartRateCompleter!.complete(data);
      }
    } else if (call.method == 'exerciseData') {
      final completer = _exerciseDataCompleter;

      if (completer != null && !completer.isCompleted) {
        _exerciseDataCompleter = null;

        try {
          DatabaseHelper dbHelper = DatabaseHelper();
          final String data = call.arguments;
          final List<dynamic> decoded = jsonDecode(data);
          final List<ActivityData> exercises = decoded
              .map((item) => ActivityData.fromMap(item as Map<String, dynamic>))
              .toList();

          await dbHelper.upsertAll(
            'activity_data',
            exercises.where((e) => e.id != null).toList(),
          );

          if (!completer.isCompleted) completer.complete();
        } catch (e, stackTrace) {
          debugPrint('Failed to decode exercise data: $e');
          if (!completer.isCompleted) completer.completeError(e, stackTrace);
        }
      }
    }
  }

  static Future<void> checkWatchConnection() async {
    try {
      final bool isConnected =
          await _platform.invokeMethod('checkWearConnection') ?? false;
      debugPrint('Watch connection status: $isConnected');
    } on PlatformException catch (e) {
      debugPrint('Failed to check watch connection: ${e.message}');
    } on MissingPluginException catch (e) {
      debugPrint('Missing plugin exception: ${e.message}');
    }
  }

  static Future<double?> getHeartRate() async {
    _heartRateCompleter = Completer<double?>();
    try {
      await _platform.invokeMethod('getHeartRate');
      return await _heartRateCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Heart rate request timed out — no response from watch');
          return null;
        },
      );
    } on PlatformException catch (e) {
      debugPrint('Failed to get Heart Rate Data: ${e.message}');
    } on MissingPluginException catch (e) {
      debugPrint('Missing Plugin Exception: ${e.message}');
    }
    return null;
  }

  static Future<void> getExerciseData() async {
    _exerciseDataCompleter = Completer<void>();

    final completer = _exerciseDataCompleter;

    await _platform.invokeMethod('getExerciseData');

    await completer!.future.timeout(const Duration(seconds: 5));
  }
}
