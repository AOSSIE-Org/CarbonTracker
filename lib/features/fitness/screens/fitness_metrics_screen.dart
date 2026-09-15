import 'dart:io';
import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/core/widgets/modal.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/features/fitness/data/fitness_data.dart';
import 'package:carbon_tracker/features/fitness/services/health_service.dart';
import 'package:carbon_tracker/features/fitness/widgets/activity_card.dart';
import 'package:carbon_tracker/features/fitness/widgets/stat_card.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/wearable/watch_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FitnessMetricsScreen extends ConsumerStatefulWidget {
  const FitnessMetricsScreen({super.key});

  @override
  ConsumerState<FitnessMetricsScreen> createState() =>
      _FitnessMetricsScreenState();
}

class _FitnessMetricsScreenState extends ConsumerState<FitnessMetricsScreen> {
  List<StatCardData> _stats = [];
  bool _isRefreshing = false;
  bool _permissionsGranted = false;
  double heartRate = 0.0;

  @override
  void initState() {
    super.initState();
    getStats();
  }

  Future<void> isWatchConnected() async {
    await WatchService.checkWatchConnection();
  }

  // Fetch health data and update the state

  Future<void> getStats() async {
    final user = ref.read(userProvider);

    if (user == null) {
      if (mounted) {
        setState(() {
          _stats = [];
          _permissionsGranted = false;
          _isRefreshing = false;
        });
      }
      return;
    }

    List<StatCardData> data = [];

    setState(() {
      _isRefreshing = true;
    });

    try {
      if (!await HealthService.requestPermissions()) {
        setState(() {
          _stats = [];
          _permissionsGranted = false;
          _isRefreshing = false;
        });
        return;
      }
      data = await HealthService.generateData();
      debugPrint('Generated stats: ${data.length}');
      if (!mounted) return;
      setState(() {
        _stats = data;
        _permissionsGranted = true;
      });
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await getStats();
  }

  // To show the current date and a greeting to the user

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
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: _isRefreshing
                ? const CircularProgressIndicator(
                    color: AppColors.textDark,
                    strokeWidth: 2,
                    constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                  )
                : IconButton(
                    onPressed: _isRefreshing ? null : _onRefresh,

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

  // To show general fitness metrics like steps, distance, calories, heart rate, blood pressure, and floors climbed

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

  // To show activities recorded on an Android watch via the companion watch app

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

    return Scaffold(
      body: user == null
          ? const Center(
              child: Text(
                'Onboarding not completed. Please complete onboarding to view fitness metrics.',
              ),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: 24),
                      _isRefreshing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.secondaryColor,
                              ),
                            )
                          : _permissionsGranted
                          ? _buildStatsGrid()
                          : const Center(
                              child: Text(
                                'No fitness metrics available. Please ensure you have granted the necessary permissions and have health data available.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.subtitleText,
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),

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

                      if (Platform.isAndroid) _buildRecentActivity(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
