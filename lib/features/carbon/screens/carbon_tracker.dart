import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/core/widgets/modal.dart';
import 'package:carbon_tracker/features/carbon/data/carbon_modal_data.dart';
import 'package:carbon_tracker/features/carbon/providers/summary_provider.dart';
import 'package:carbon_tracker/features/carbon/widgets/carbon_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Type { emitted, saved }

class CarbonTrackerScreen extends ConsumerStatefulWidget {
  const CarbonTrackerScreen({super.key});

  @override
  ConsumerState<CarbonTrackerScreen> createState() =>
      _CarbonTrackerScreenState();
}

class _CarbonTrackerScreenState extends ConsumerState<CarbonTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CarbonEmittedTodayCard(),
              const SizedBox(height: 20),
              const _WeeklyImpactCard(),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.cloud_off_outlined,
                      label: 'Total Emitted This\nWeek',
                      type: Type.emitted,
                      background: Colors.white,
                      foreground: Colors.black87,
                      iconColor: Colors.black45,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.eco_outlined,
                      label: 'Total Saved This\nWeek',
                      type: Type.saved,
                      background: AppColors.oliveGreen,
                      foreground: Colors.white,
                      iconColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Nature's Recommendations",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      showInfoModal(
                        context,
                        carbonModalTitle,
                        carbonModalData,
                        "Close",
                      );
                    },
                    tooltip: 'More information about carbon footprint',
                    icon: const Icon(Icons.info_outline, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _RecommendationCard(
                icon: Icons.directions_walk,
                title: 'You traveled 400m by car.',
                highlight: '0.2 kg CO₂',
                bodyPrefix: 'Walking could have saved ',
                bodySuffix:
                    '. The weather today is perfect for a short stroll.',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarbonEmittedTodayCard extends ConsumerWidget {
  const _CarbonEmittedTodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          'CARBON EMITTED TODAY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.secondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ref
                      .watch(summaryProvider)
                      ?.todayCarbonEmitted
                      .toStringAsFixed(2) ??
                  '0.00',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                'kg',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.metricsBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.park_outlined,
                size: 16,
                color: AppColors.secondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'travel greener today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyImpactCard extends StatelessWidget {
  const _WeeklyImpactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.metricsBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Impact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: Colors.grey.shade400, label: 'Emitted'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.oliveGreen, label: 'Saved'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          CarbonChart(),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}

class _StatCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final Type type; // 'emitted' or 'saved'
  final Color background;
  final Color foreground;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.type,
    required this.background,
    required this.foreground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalEmitted = ref.watch(summaryProvider)?.totalCarbonEmitted ?? 0.0;
    final totalSaved = ref.watch(summaryProvider)?.totalCarbonSaved ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background == Colors.white
            ? background.withValues(alpha: 0.8)
            : background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: background == Colors.white
              ? AppColors.greyBorder
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: foreground, height: 1.3),
          ),
          const SizedBox(height: 10),
          Text(
            type == Type.emitted
                ? '${totalEmitted.toStringAsFixed(2)} kg'
                : '${totalSaved.toStringAsFixed(2)} kg',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String highlight;
  final String bodyPrefix;
  final String bodySuffix;

  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.highlight,
    required this.bodyPrefix,
    required this.bodySuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
              children: [
                TextSpan(text: bodyPrefix),
                TextSpan(
                  text: highlight,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                  ),
                ),
                TextSpan(text: bodySuffix),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
