import 'dart:io';
import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class IHealthPermissionService {
  Future<HealthPermissionResult> requestPermissions();
  Future<HealthPermissionResult> getPermissionStatus();
  Future<bool> openSettings();
  Future<bool> openHealthConnectPlayStore();
}

class HealthPermissionService implements IHealthPermissionService {
  HealthPermissionService({
    MethodChannel? channel,
    IHealthService? healthService,
  }) : _channel =
           channel ??
           const MethodChannel('org.aossie.carbon_tracker/matchmaking'),
       _healthService = healthService ?? HealthService();

  final MethodChannel _channel;
  final IHealthService _healthService;

  bool get _isAndroid =>
      !kIsWeb &&
      (Platform.isAndroid ||
          debugDefaultTargetPlatformOverride == TargetPlatform.android);

  bool get _isIOS =>
      !kIsWeb &&
      (Platform.isIOS ||
          debugDefaultTargetPlatformOverride == TargetPlatform.iOS);

  @override
  Future<HealthPermissionResult> requestPermissions() async {
    if (_isAndroid) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'showMatchmakingModal',
        );
        return HealthPermissionResult.fromMap(result);
      } on PlatformException catch (e) {
        // Handle backward-compatibility with older native builds if any
        if (e.code == 'HEALTH_CONNECT_UNAVAILABLE') {
          return HealthPermissionResult(
            status: HealthPermissionStatus.unavailable,
            message: e.message ?? 'Health Connect is unavailable',
          );
        }
        if (e.code == 'PERMISSION_DENIED') {
          return HealthPermissionResult(
            status: HealthPermissionStatus.denied,
            message: e.message ?? 'Health permissions denied',
          );
        }
        // Keep real, unexpected errors surfacing as exceptions
        rethrow;
      } on MissingPluginException {
        final granted = await _healthService.requestPermissions();
        return HealthPermissionResult(
          status: granted
              ? HealthPermissionStatus.granted
              : HealthPermissionStatus.denied,
        );
      }
    }

    if (_isIOS) {
      try {
        final granted = await _healthService.requestPermissions();
        if (granted) {
          return const HealthPermissionResult(
            status: HealthPermissionStatus.granted,
            message: 'HealthKit permissions granted',
          );
        } else {
          return const HealthPermissionResult(
            status: HealthPermissionStatus.denied,
            message: 'HealthKit permissions denied',
          );
        }
      } catch (e) {
        debugPrint('Error requesting iOS HealthKit permissions: $e');
        rethrow;
      }
    }

    // Default for other platforms/web/desktop
    final granted = await _healthService.requestPermissions();
    return HealthPermissionResult(
      status: granted
          ? HealthPermissionStatus.granted
          : HealthPermissionStatus.denied,
    );
  }

  @override
  Future<HealthPermissionResult> getPermissionStatus() async {
    if (_isAndroid) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getHealthPermissionStatus',
        );
        return HealthPermissionResult.fromMap(result);
      } on PlatformException catch (e) {
        if (e.code == 'HEALTH_CONNECT_UNAVAILABLE') {
          return const HealthPermissionResult(
            status: HealthPermissionStatus.unavailable,
          );
        }
        if (e.code == 'PERMISSION_DENIED') {
          return const HealthPermissionResult(
            status: HealthPermissionStatus.denied,
          );
        }
        rethrow;
      } on MissingPluginException {
        // Fallback for mocked or unsupported environments
        final hasPerms = await _healthService.hasGrantedPermissions();
        return HealthPermissionResult(
          status: hasPerms
              ? HealthPermissionStatus.granted
              : HealthPermissionStatus.denied,
        );
      }
    }

    if (_isIOS) {
      final hasPerms = await _healthService.hasGrantedPermissions();
      return HealthPermissionResult(
        status: hasPerms
            ? HealthPermissionStatus.granted
            : HealthPermissionStatus.denied,
      );
    }

    final hasPerms = await _healthService.hasGrantedPermissions();
    return HealthPermissionResult(
      status: hasPerms
          ? HealthPermissionStatus.granted
          : HealthPermissionStatus.denied,
    );
  }

  @override
  Future<bool> openSettings() async {
    if (_isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>(
          'openHealthConnectSettings',
        );
        return result ?? false;
      } catch (e) {
        debugPrint('Error opening Android Health Connect settings: $e');
      }
    }

    // Fallback: try opening app-settings via url_launcher
    try {
      final uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (_) {}

    return false;
  }

  @override
  Future<bool> openHealthConnectPlayStore() async {
    if (_isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>(
          'openHealthConnectPlayStore',
        );
        return result ?? false;
      } catch (e) {
        debugPrint('Native openHealthConnectPlayStore failed: $e');
      }
    }

    // Fallback via web URL launcher
    try {
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
      );
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching Play Store URL: $e');
    }

    return false;
  }
}
