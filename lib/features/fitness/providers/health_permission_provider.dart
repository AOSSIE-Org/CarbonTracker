import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:carbon_tracker/features/fitness/services/health_permission_service.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final healthPermissionServiceProvider = Provider<IHealthPermissionService>(
  (ref) =>
      HealthPermissionService(healthService: ref.watch(healthServiceProvider)),
);

class HealthPermissionStatusNotifier extends Notifier<HealthPermissionResult?> {
  @override
  HealthPermissionResult? build() => null;

  void update(HealthPermissionResult? result) {
    state = result;
  }

  Future<HealthPermissionResult> checkStatus() async {
    final service = ref.read(healthPermissionServiceProvider);
    final result = await service.getPermissionStatus();
    state = result;
    return result;
  }

  Future<HealthPermissionResult> requestPermissions() async {
    final service = ref.read(healthPermissionServiceProvider);
    final result = await service.requestPermissions();
    state = result;
    return result;
  }
}

final healthPermissionStatusProvider =
    NotifierProvider<HealthPermissionStatusNotifier, HealthPermissionResult?>(
      HealthPermissionStatusNotifier.new,
    );
