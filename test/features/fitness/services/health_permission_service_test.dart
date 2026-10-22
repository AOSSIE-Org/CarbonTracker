import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:carbon_tracker/features/fitness/services/health_permission_service.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

class _FakeHealthService implements IHealthService {
  _FakeHealthService();

  bool permissionsGranted = true;

  @override
  Future<bool> requestPermissions() async => permissionsGranted;

  @override
  Future<bool> hasGrantedPermissions() async => permissionsGranted;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<StatCardData>> generateData() async => [];

  @override
  Future<int> getTodaySteps() async => 0;

  @override
  Future<List<HealthDataPoint>> getHealthData() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthPermissionResult model mapping', () {
    test(
      'maps granted / completed / not_possible to HealthPermissionStatus.granted',
      () {
        final res1 = HealthPermissionResult.fromMap({
          'status': 'granted',
          'grantedPermissions': ['StepsRecord', 'DistanceRecord'],
          'message': 'All granted',
        });
        expect(res1.status, HealthPermissionStatus.granted);
        expect(res1.isGranted, isTrue);
        expect(res1.hasAccess, isTrue);
        expect(res1.grantedPermissions, ['StepsRecord', 'DistanceRecord']);

        final res2 = HealthPermissionResult.fromMap({'status': 'completed'});
        expect(res2.status, HealthPermissionStatus.granted);

        final res3 = HealthPermissionResult.fromMap({'status': 'not_possible'});
        expect(res3.status, HealthPermissionStatus.granted);
      },
    );

    test('maps partial to HealthPermissionStatus.partial', () {
      final res = HealthPermissionResult.fromMap({
        'status': 'partial',
        'grantedPermissions': ['StepsRecord'],
        'message': 'Partially granted',
      });
      expect(res.status, HealthPermissionStatus.partial);
      expect(res.isPartial, isTrue);
      expect(res.hasAccess, isTrue);
      expect(res.isGranted, isFalse);
      expect(res.grantedPermissions, ['StepsRecord']);
    });

    test('maps denied / cancelled to HealthPermissionStatus.denied', () {
      final res1 = HealthPermissionResult.fromMap({
        'status': 'denied',
        'grantedPermissions': [],
      });
      expect(res1.status, HealthPermissionStatus.denied);
      expect(res1.isDenied, isTrue);
      expect(res1.hasAccess, isFalse);

      final res2 = HealthPermissionResult.fromMap({'status': 'cancelled'});
      expect(res2.status, HealthPermissionStatus.denied);
    });

    test(
      'maps unavailable / not_available to HealthPermissionStatus.unavailable',
      () {
        final res1 = HealthPermissionResult.fromMap({
          'status': 'unavailable',
          'message': 'Not available on device',
        });
        expect(res1.status, HealthPermissionStatus.unavailable);
        expect(res1.isUnavailable, isTrue);
        expect(res1.hasAccess, isFalse);

        final res2 = HealthPermissionResult.fromMap({
          'status': 'not_available',
        });
        expect(res2.status, HealthPermissionStatus.unavailable);
      },
    );

    test('maps null or unknown status to denied', () {
      final resNull = HealthPermissionResult.fromMap(null);
      expect(resNull.status, HealthPermissionStatus.denied);

      final resUnknown = HealthPermissionResult.fromMap({'status': 'unknown'});
      expect(resUnknown.status, HealthPermissionStatus.denied);
    });
  });

  group('HealthPermissionService on Android', () {
    const channel = MethodChannel('org.aossie.carbon_tracker/matchmaking');
    late HealthPermissionService service;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      service = HealthPermissionService(channel: channel);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'requestPermissions returns granted when native returns granted',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'showMatchmakingModal') {
                return {
                  'status': 'granted',
                  'grantedPermissions': ['StepsRecord', 'DistanceRecord'],
                };
              }
              return null;
            });

        final result = await service.requestPermissions();
        expect(result.status, HealthPermissionStatus.granted);
        expect(result.grantedPermissions, ['StepsRecord', 'DistanceRecord']);
      },
    );

    test(
      'requestPermissions returns partial when native returns partial',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'showMatchmakingModal') {
                return {
                  'status': 'partial',
                  'grantedPermissions': ['StepsRecord'],
                };
              }
              return null;
            });

        final result = await service.requestPermissions();
        expect(result.status, HealthPermissionStatus.partial);
        expect(result.grantedPermissions, ['StepsRecord']);
      },
    );

    test(
      'requestPermissions returns denied when native returns denied',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'showMatchmakingModal') {
                return {'status': 'denied', 'grantedPermissions': []};
              }
              return null;
            });

        final result = await service.requestPermissions();
        expect(result.status, HealthPermissionStatus.denied);
      },
    );

    test(
      'requestPermissions returns unavailable when native returns unavailable',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'showMatchmakingModal') {
                return {
                  'status': 'unavailable',
                  'message': 'Health Connect missing',
                };
              }
              return null;
            });

        final result = await service.requestPermissions();
        expect(result.status, HealthPermissionStatus.unavailable);
      },
    );

    test(
      'unexpected error from native channel still surfaces as PlatformException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw PlatformException(
                code: 'UNEXPECTED_SYSTEM_FAILURE',
                message: 'Fatal native exception',
              );
            });

        expect(
          () => service.requestPermissions(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNEXPECTED_SYSTEM_FAILURE',
            ),
          ),
        );
      },
    );

    test(
      'openSettings calls openHealthConnectSettings on native channel',
      () async {
        bool called = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'openHealthConnectSettings') {
                called = true;
                return true;
              }
              return null;
            });

        final success = await service.openSettings();
        expect(called, isTrue);
        expect(success, isTrue);
      },
    );

    test(
      'openHealthConnectPlayStore calls openHealthConnectPlayStore on native channel',
      () async {
        bool called = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'openHealthConnectPlayStore') {
                called = true;
                return true;
              }
              return null;
            });

        final success = await service.openHealthConnectPlayStore();
        expect(called, isTrue);
        expect(success, isTrue);
      },
    );
  });

  group('HealthPermissionService on iOS', () {
    late _FakeHealthService fakeHealthService;
    late HealthPermissionService service;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      fakeHealthService = _FakeHealthService();
      service = HealthPermissionService(healthService: fakeHealthService);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'requestPermissions returns granted when HealthKit grants permission',
      () async {
        fakeHealthService.permissionsGranted = true;
        final result = await service.requestPermissions();
        expect(result.status, HealthPermissionStatus.granted);
      },
    );

    test(
      'requestPermissions returns denied when HealthKit denies permission',
      () async {
        fakeHealthService.permissionsGranted = false;
        final result = await service.requestPermissions();
        expect(result.status, HealthPermissionStatus.denied);
      },
    );
  });
}
