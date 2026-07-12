import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/features/map/services/map_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final bool isActive;

  const MapScreen({super.key, required this.isActive});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _errMessage = "";
  String _currentLocationQuery = "";
  String _destinationLocationQuery = "";
  List<String?> _currentLocations = [];
  List<String?> _destinationLocations = [];
  bool _isLoading = false;

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive != widget.isActive && widget.isActive) {
      getLocation();
    }
  }

  Future<void> getLocation() async {
    try {
      if (!await MapService.isPermissionGranted()) {
        setState(() {
          _errMessage =
              "Something went wrong while fetching location permissions. Please check your device settings.";
        });
      }

      Position position = await MapService.getCurrentPosition();
      String locationString = await MapService.retrieveAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentLocationQuery = locationString;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errMessage = e.toString();
      });
    }
  }

  Future<void> fetchAddresses() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final searchResult = await MapService.queryPlaces(
        _currentLocationQuery,
        _destinationLocationQuery,
      );

      setState(() {
        _currentLocations = searchResult.currentLocations;
        _destinationLocations = searchResult.destinationLocations;
      });

      debugPrint("Current locations : ${searchResult.currentLocations}");
      debugPrint(
        "Destination locations : ${searchResult.destinationLocations}",
      );
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: _errMessage.isNotEmpty
          ? Center(child: Text(_errMessage))
          : AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Stack(
                  children: [
                    // Map / background image goes here
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          'assets/images/map_placeholder.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Floating location card
                    Positioned(
                      top: topPadding + size.height * 0.02,
                      // TODO MAKE THIS DYNAMIC BASED ON SCREEN SIZE
                      left: 16,
                      right: 16,
                      child: _LocationCard(
                        currentLocationChanged: (value) {
                          setState(() {
                            _currentLocationQuery = value;
                          });
                        },
                        onCurrentSelection: () {
                          setState(() {
                            _currentLocations = [];
                          });
                        },
                        currentLocations: _currentLocations,

                        destinationLocationChanged: (value) {
                          setState(() {
                            _destinationLocationQuery = value;
                          });
                        },
                        destinationLocations: _destinationLocations,
                        onDestinationSelection: () {
                          setState(() {
                            _destinationLocations = [];
                          });
                        },
                      ),
                    ),

                    // Floating nav/locate button
                    Positioned(
                      bottom: size.height * 0.05,
                      right: 20,
                      child: _LocateButton(
                        onPressed:
                            _destinationLocationQuery.isNotEmpty && !_isLoading
                            ? () {
                                fetchAddresses();
                              }
                            : null,

                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LocationCard extends StatefulWidget {
  final ValueChanged<String> currentLocationChanged;
  final ValueChanged<String> destinationLocationChanged;
  final VoidCallback onCurrentSelection;
  final VoidCallback onDestinationSelection;
  final List<String?> currentLocations;
  final List<String?> destinationLocations;

  const _LocationCard({
    required this.currentLocationChanged,
    required this.destinationLocationChanged,
    required this.currentLocations,
    required this.destinationLocations,
    required this.onDestinationSelection,
    required this.onCurrentSelection,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  late final TextEditingController currentController;
  late final TextEditingController destinationController;

  @override
  void initState() {
    super.initState();
    currentController = TextEditingController();
    destinationController = TextEditingController();
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
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
          _LocationRow(
            icon: Icons.my_location,
            label: 'Current Location',
            placeholder: 'Where are you at?',
            onChanged: widget.currentLocationChanged,
            locations: widget.currentLocations,
            onSelection: widget.onCurrentSelection,
            controller: currentController,
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

          _LocationRow(
            icon: Icons.location_on_outlined,
            label: 'Destination',
            placeholder: 'Where are you going?',
            onChanged: widget.destinationLocationChanged,
            locations: widget.destinationLocations,
            onSelection: widget.onDestinationSelection,
            controller: destinationController,
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final List<String?> locations;
  final TextEditingController controller;
  final VoidCallback onSelection;

  const _LocationRow({
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.onChanged,
    required this.locations,
    required this.controller,
    required this.onSelection,
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
                        color: AppColors.minisculeText,
                      ),
                    ),
                    TextField(
                      controller: controller,
                      onChanged: (value) {
                        onChanged(value);
                      },
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: placeholder,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.minisculeText),
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
            onSelected: (selectedLocation) {
              controller.text = selectedLocation;
              onSelection();
              onChanged(selectedLocation);
            },
          ),
      ],
    );
  }
}

class LocationOptions extends StatelessWidget {
  final List<String?> options;
  final ValueChanged<String> onSelected;

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
          return InkWell(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.metricsBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                options[index] ?? '',
                style: TextStyle(fontSize: 14, color: AppColors.subtitleText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () {
              onSelected(options[index] ?? '');
            },
          );
        },
      ),
    );
  }
}

class _LocateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _LocateButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: AppColors.primaryColor,
        minimumSize: const Size(56, 56),
      ),

      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.check_rounded,
              color: AppColors.secondaryColor,
              size: 30,
              fontWeight: FontWeight.bold,
            ),
    );
  }
}
