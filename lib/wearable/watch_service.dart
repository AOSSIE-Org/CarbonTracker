import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WatchService {
  static const MethodChannel _platform = MethodChannel(
    'org.aossie.carbon_tracker/wear_connection',
  );

  void initialize() {
    _platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'watchData') {
      final String data = call.arguments;
      debugPrint("Received watch data : $data");
    }
  }

  static Future<void> checkWatchConnection() async {
    try {
      final bool isConnected = await _platform.invokeMethod(
        'checkWearConnection',
      ) ?? false;
      debugPrint('Watch connection status: $isConnected');
    } on PlatformException catch (e) {
      debugPrint('Failed to check watch connection: ${e.message}');
    } on MissingPluginException catch (e) {
      debugPrint('Missing plugin exception: ${e.message}');
    }
  }
}
