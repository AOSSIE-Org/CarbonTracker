import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:flutter/material.dart';

class LocationOptions extends StatelessWidget {
  final List<SearchResult?> options;
  final ValueChanged<SearchResult> onSelected;

  const LocationOptions({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: options.length,
        itemBuilder: (context, index) {
          if (options[index] == null ||
              options[index]!.locationString == null ||
              options[index]!.locationString!.isEmpty ||
              options[index]!.lat == null ||
              options[index]!.lon == null) {
            return const SizedBox.shrink();
          }
          return InkWell(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                options[index]!.locationString ?? '',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () {
              onSelected(options[index]!);
            },
          );
        },
      ),
    );
  }
}
