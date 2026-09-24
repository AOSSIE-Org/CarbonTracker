import 'package:carbon_tracker/database/models/activity.dart';
import 'package:carbon_tracker/features/fitness/ui/activity_style.dart';
import 'package:flutter/material.dart';
import 'package:carbon_tracker/core/config/app_constants.dart';

import 'package:carbon_tracker/core/helpers/date_format.dart';

class ActivityCard extends StatefulWidget {
  final ActivityData activity;

  const ActivityCard({super.key, required this.activity});

  @override
  State<ActivityCard> createState() => ActivityCardState();
}

class ActivityCardState extends State<ActivityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    ActivityKind kind = ActivityKind.fromDb(widget.activity.activityType);
    ActivityStyle style = ActivityStyle.forKind(kind);
    return AnimatedSize(
      duration: Duration(milliseconds: 500),
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: AppColors.metricsBackgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${formatDate(widget.activity.startTime)} '
                        '(${widget.activity.endTime == null ? "ongoing" : "${formatTime(widget.activity.startTime)} - ${formatTime(widget.activity.endTime!)}"})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.minisculeText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  tooltip: _isExpanded
                      ? 'Collapse activity details'
                      : 'Expand activity details',
                  icon: Icon(
                    _isExpanded ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF888780),
                    size: 18,
                  ),
                ),
              ],
            ),

            if (_isExpanded)
              Column(
                children: [
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFD3D1C7), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ActivityStat(
                        label: 'Calories',
                        value: widget.activity.caloriesBurned.toStringAsFixed(
                          2,
                        ),
                        unit: 'kcal',
                      ),
                      _ActivityStat(
                        label: 'Distance',
                        value: widget.activity.distance.toStringAsFixed(2),
                        unit: 'km',
                      ),
                      _ActivityStat(
                        label: 'Heart Rate',
                        value: widget.activity.heartRate != null
                            ? widget.activity.heartRate!.toStringAsFixed(0)
                            : 'N/A',
                        unit: 'bpm',
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _ActivityStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.subtitleText),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2A),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
            ),
          ],
        ),
      ],
    );
  }
}
