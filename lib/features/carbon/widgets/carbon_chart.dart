import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/features/carbon/models/summary_model.dart';
import 'package:carbon_tracker/features/carbon/providers/summary_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CarbonChart extends ConsumerWidget {
  const CarbonChart({super.key});

  static const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const symbols = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<int> dayIndexes = [0, 1, 2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider)?.summaryData;

    if (summary == null || summary.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.minisculeText,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => AppColors.greyBorder,
                tooltipBorder: BorderSide(
                  color: Colors.grey.shade400,
                  width: 1,
                ),
              ),
            ),
            barGroups: dayIndexes.map((i) {
              WeeklyData data = summary[days[i]] ?? const WeeklyData();

              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data.carbonEmitted,
                    color: Colors.grey.shade400,
                    width: 10,
                    borderRadius: BorderRadius.circular(0),
                  ),
                  BarChartRodData(
                    toY: data.carbonSaved,
                    color: AppColors.oliveGreen,
                    width: 10,
                    borderRadius: BorderRadius.circular(0),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
                axisNameWidget: Center(
                  child: Text(
                    'Emissions (kg)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.minisculeText,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value >= days.length) {
                      return const SizedBox.shrink();
                    }

                    return SizedBox(
                      height: 20,

                      child: Center(
                        child: Text(
                          symbols[value.toInt()],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.minisculeText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            alignment: BarChartAlignment.spaceEvenly,
          ),
          duration: Duration(milliseconds: 150),
          curve: Curves.linear,
        ),
      ),
    );
  }
}
