import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WatchService {
  static const MethodChannel _platform = MethodChannel(
    'org.aossie.carbon_tracker/wear_connection',
  );

  static Completer<double?>? _heartRateCompleter;

  void initialize() {
    _platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    // Handle incoming method calls from the native side

    if (call.method == 'heartRateData') {
      final double? data = double.tryParse(call.arguments.toString());
      debugPrint("Received Heart Rate Data : $data");

      if (_heartRateCompleter != null && !_heartRateCompleter!.isCompleted) {
        _heartRateCompleter!.complete(data);
      }
    } else if (call.method == 'exerciseData') {
      final String data = call.arguments;
      debugPrint("Received Exercise Data : $data");
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
      return _heartRateCompleter!.future.timeout(
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
    try {
      final exerciseData = await _platform.invokeMethod('getExerciseData');

      debugPrint('Exercise Data: $exerciseData');
    } on PlatformException catch (e) {
      debugPrint('Failed to get Exercise Data: ${e.message}');
    } on MissingPluginException catch (e) {
      debugPrint('Missing Plugin Exception: ${e.message}');
    }
  }
}
