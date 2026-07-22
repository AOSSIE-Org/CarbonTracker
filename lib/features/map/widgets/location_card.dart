import 'package:carbon_tracker/features/map/models/location_type.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/widgets/location_row.dart';
import 'package:flutter/material.dart';

class LocationCard extends StatefulWidget {
  final SearchResult? currentLocation;
  final ValueChanged<SearchResult> onCurrentSelection;
  final ValueChanged<SearchResult> onDestinationSelection;
  final List<SearchResult?> currentLocations;
  final List<SearchResult?> destinationLocations;
  final ValueChanged<String> onCurrentChanged;
  final ValueChanged<String> onDestinationChanged;

  const LocationCard({
    super.key,
    this.currentLocation,
    required this.currentLocations,
    required this.destinationLocations,
    required this.onDestinationSelection,
    required this.onCurrentSelection,
    required this.onCurrentChanged,
    required this.onDestinationChanged,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  late final TextEditingController currentController;
  late final TextEditingController destinationController;

  @override
  void initState() {
    super.initState();
    currentController = TextEditingController();
    destinationController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant LocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLocation?.locationString !=
        oldWidget.currentLocation?.locationString) {
      currentController.text = widget.currentLocation?.locationString ?? '';
    }
  }

  @override
  void dispose() {
    currentController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocationRow(
            icon: Icons.my_location,
            label: 'Current Location',
            placeholder: 'Where are you at?',
            locations: widget.currentLocations,
            onSelection: widget.onCurrentSelection,
            controller: currentController,
            onChanged: widget.onCurrentChanged,
            type: LocationType.current,
          ),
          if (widget.currentLocations.isEmpty &&
              widget.destinationLocations.isEmpty)
            Center(
              child: Container(
                height: 20,
                width: 1,
                color: Colors.grey.shade400,
              ),
            ),

          LocationRow(
            icon: Icons.location_on_outlined,
            label: 'Destination',
            placeholder: 'Where are you going?',
            locations: widget.destinationLocations,
            onSelection: widget.onDestinationSelection,
            controller: destinationController,
            onChanged: widget.onDestinationChanged,
            type: LocationType.destination,
          ),
        ],
      ),
    );
  }
}
