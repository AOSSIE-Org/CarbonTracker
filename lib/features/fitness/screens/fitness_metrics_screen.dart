import 'dart:async';
import 'dart:io';
import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/core/widgets/modal.dart';
import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/activity.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:carbon_tracker/features/fitness/providers/health_permission_provider.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:carbon_tracker/features/fitness/widgets/activity_card.dart';
import 'package:carbon_tracker/features/fitness/widgets/health_permission_banner.dart';
import 'package:carbon_tracker/features/fitness/widgets/stat_card.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/wearable/watch_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FitnessMetricsScreen extends ConsumerStatefulWidget {
  const FitnessMetricsScreen({super.key});

  @override
  ConsumerState<FitnessMetricsScreen> createState() =>
      _FitnessMetricsScreenState();
}

class _FitnessMetricsScreenState extends ConsumerState<FitnessMetricsScreen>
    with WidgetsBindingObserver {
  List<StatCardData> _stats = [];
  bool _isRefreshing = false;
  bool _permissionsGranted = false;
  bool _isBannerDismissed = false;
  double heartRate = 0.0;
  List<ActivityData> activities = [];
  late final IHealthService _healthService;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _healthService = ref.read(healthServiceProvider);
    _initAndRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsOnResume();
    }
  }

  Future<void> _checkPermissionsOnResume() async {
    try {
      final status = await ref
          .read(healthPermissionServiceProvider)
          .getPermissionStatus();
      if (!mounted) return;
      ref.read(healthPermissionStatusProvider.notifier).update(status);
      if (status.isGranted) {
        setState(() {
          _isBannerDismissed = false;
        });
        await _onRefresh();
      } else if (status.isPartial) {
        await _onRefresh();
      } else {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error re-checking permissions on resume: $e');
    }
  }

  Future<void> _initAndRefresh() async {
    try {
      final status = await ref
          .read(healthPermissionServiceProvider)
          .getPermissionStatus();
      if (mounted) {
        ref.read(healthPermissionStatusProvider.notifier).update(status);
      }
    } catch (_) {}
    await _onRefresh();
  }

  // Fetch health data and update the state
  Future<void> getStats() async {
    List<StatCardData> data = [];
    data = await _healthService.generateData();
    debugPrint('Generated stats: ${data.length}');
    if (!mounted) return;
    setState(() {
      _stats = data;
      _permissionsGranted = true;
    });
  }

  Future<void> _handleBannerAction() async {
    final permService = ref.read(healthPermissionServiceProvider);
    final currentStatus = ref.read(healthPermissionStatusProvider);

    if (currentStatus?.isUnavailable == true) {
      await permService.openHealthConnectPlayStore();
      return;
    }

    try {
      final result = await permService.requestPermissions();
      if (!mounted) return;
      ref.read(healthPermissionStatusProvider.notifier).update(result);
      if (result.isGranted) {
        setState(() {
          _isBannerDismissed = false;
        });
        await _onRefresh();
      } else {
        await permService.openSettings();
      }
    } catch (e) {
      debugPrint('Error during banner permission request: $e');
      await permService.openSettings();
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    try {
      setState(() {
        _isRefreshing = true;
      });
      final user = ref.read(userProvider);

      if (user == null) {
        setState(() {
          _stats = [];
          _permissionsGranted = false;
          _isRefreshing = false;
        });
        return;
      }

      // Check current permission status
      final permStatus = ref.read(healthPermissionStatusProvider);
      bool hasPermission = false;

      if (permStatus != null) {
        hasPermission = permStatus.hasAccess;
      } else {
        final statusResult = await ref
            .read(healthPermissionServiceProvider)
            .getPermissionStatus();
        if (mounted) {
          ref
              .read(healthPermissionStatusProvider.notifier)
              .update(statusResult);
        }
        hasPermission = statusResult.hasAccess;
      }

      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _stats = [];
          _permissionsGranted = false;
          _isRefreshing = false;
        });
        return;
      }

      await Future.wait([
        getStats(),
        if (Platform.isAndroid) getExerciseData(),
      ]);
    } catch (e) {
      debugPrint('Error during refresh: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> getExerciseData() async {
    try {
      await WatchService.getExerciseData();
    } on TimeoutException catch (e) {
      debugPrint('Timeout while fetching exercise data: $e');
    } on PlatformException catch (e) {
      debugPrint(
        'PlatformException while fetching exercise data: ${e.message}',
      );
    } on MissingPluginException catch (e) {
      debugPrint(
        'MissingPluginException while fetching exercise data: ${e.message}',
      );
    } catch (e) {
      debugPrint('Error while fetching exercise data: $e');
    }
    try {
      final activityData = await _dbHelper.queryAll(
        'activity_data',
        ActivityData.fromMap,
      );
      activityData.sort((a, b) => b.startTime.compareTo(a.startTime));
      if (!mounted) return;
      setState(() => activities = activityData);
    } catch (e) {
      debugPrint('Error while loading stored activities: $e');
    }
  }

  Widget _buildHeader(User user) {
    String date = DateFormat("EEEE, MMM d").format(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: TextStyle(fontSize: 13, color: AppColors.subtitleText),
            ),
            const SizedBox(height: 4),
            Text(
              'Hello, ${user.name}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (!_isRefreshing)
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: IconButton(
                onPressed: _onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textDark,
                  size: 30,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _stats
          .map(
            (stat) => StatCard(
              icon: stat.icon,
              iconColor: stat.iconColor,
              iconBg: stat.iconBg,
              label: stat.label,
              value: stat.value,
              unit: stat.unit,
            ),
          )
          .toList(),
    );
  }

  Widget _buildDegradedEmptyState(HealthPermissionResult? permStatus) {
    final isUnavailable = permStatus?.isUnavailable == true;
    final actionLabel = isUnavailable
        ? 'Install Health Connect'
        : 'Grant Permissions';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              size: 48,
              color: AppColors.subtitleText,
            ),
            const SizedBox(height: 12),
            const Text(
              'No fitness metrics available. Please ensure you have granted the necessary permissions and have health data available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.subtitleText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('empty_state_grant_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryColor,
                side: const BorderSide(color: AppColors.secondaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _handleBannerAction,
              icon: Icon(
                isUnavailable
                    ? Icons.download_rounded
                    : Icons.lock_open_rounded,
                size: 18,
              ),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        ListView.builder(
          itemBuilder: (context, index) =>
              ActivityCard(activity: activities[index]),
          itemCount: activities.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final permStatus = ref.watch(healthPermissionStatusProvider);
    final showBanner =
        !_isBannerDismissed && permStatus != null && !permStatus.isGranted;

    return Scaffold(
      body: user == null
          ? const Center(
              child: Text(
                'Onboarding not completed. Please complete onboarding to view fitness metrics.',
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(user),
                    const SizedBox(height: 16),
                    if (showBanner) ...[
                      HealthPermissionBanner(
                        statusResult: permStatus,
                        onDismiss: () =>
                            setState(() => _isBannerDismissed = true),
                        onAction: _handleBannerAction,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _isRefreshing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.secondaryColor,
                            ),
                          )
                        : _permissionsGranted
                        ? _buildStatsGrid()
                        : _buildDegradedEmptyState(permStatus),
                    const SizedBox(height: 20),
                    if (!_isRefreshing)
                      GestureDetector(
                        onTap: () {
                          showInfoModal(
                            context,
                            "Why Some Health Metrics Aren’t Available",
                            metricsModalData,
                            'Close',
                          );
                        },
                        child: const Text(
                          "Can't see some metrics?",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    if (Platform.isAndroid && !_isRefreshing)
                      _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }
}
