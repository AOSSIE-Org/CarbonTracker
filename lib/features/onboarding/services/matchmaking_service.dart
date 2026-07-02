import 'package:flutter/services.dart';

class MatchmakingService {
  static const platform = MethodChannel(
    'org.aossie.carbon_tracker/matchmaking',
  );

  MatchmakingService._();

  static Future<String> showMatchmakingModal() async {
    try {
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'showMatchmakingModal',
      );

      switch (result?["status"]) {
        case "completed":
        case "cancelled":
        case "not_available":
        case "not_possible":
          return "proceed";

        default:
          return "Unexpected result from matchmaking modal";
      }
    } on PlatformException catch (e) {
      return "Failed to show matchmaking modal: ${e.message}";
    } catch (e) {
      return "Unexpected error showing matchmaking modal: $e";
    }
  }
}
