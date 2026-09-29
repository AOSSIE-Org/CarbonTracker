// Provider for health permission request function

import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final healthPermissionProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () => HealthService().requestPermissions(),
);
