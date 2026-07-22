import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/features/map/models/location_type.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/widgets/location_options.dart';
import 'package:flutter/material.dart';

class LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String placeholder;
  final List<SearchResult?> locations;
  final TextEditingController controller;
  final ValueChanged<SearchResult> onSelection;
  final ValueChanged<String> onChanged;
  final LocationType type;

  const LocationRow({
    super.key,
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.locations,
    required this.controller,
    required this.onSelection,
    required this.onChanged,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.metricsBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.secondaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    TextField(
                      controller: controller,
                      onChanged: (value) {
                        onChanged(value);
                      },
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitleText,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: placeholder,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.subtitleText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (locations.isNotEmpty)
          LocationOptions(
            options: locations,
            onSelected: (SearchResult selectedLocation) {
              controller.text = selectedLocation.locationString!;
              onSelection(selectedLocation);
            },
          ),
      ],
    );
  }
}
