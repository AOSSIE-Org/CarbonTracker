// Provider for matchmaking runner function

import 'package:carbon_tracker/features/onboarding/services/matchmaking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchmakingRunnerProvider = Provider<Future<String> Function()>(
  (ref) => MatchmakingService.showMatchmakingModal,
);
