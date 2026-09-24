import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/core/enums/transport_modes.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/features/carbon/helpers/carbon_calculator.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/repositories/trip_repository.dart';
import 'package:carbon_tracker/features/map/services/location_service.dart';
import 'package:carbon_tracker/features/map/widgets/location_button.dart';
import 'package:carbon_tracker/features/map/widgets/location_card.dart';
import 'package:carbon_tracker/features/map/widgets/map_modal.dart';
import 'package:carbon_tracker/features/map/widgets/map_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool isActive;

  const MapScreen({super.key, required this.isActive});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _errMessage = "";
  SearchResult? _currentLocationQuery;
  SearchResult? _destinationLocationQuery;
  String _currentLocationString = "";
  String _destinationLocationString = "";
  List<SearchResult?> _currentLocations = [];
  List<SearchResult?> _destinationLocations = [];
  bool _currentLocationSelected = false;
  bool _destinationLocationSelected = false;
  TransportModes? _selectedMode;
  bool _startMapRoute = false;
  int? _currentTripId;
  double? _totalDistanceKm;
  double? _estimatedTimeMinutes;
  bool _isLoading = false;
  bool _isStartingTrip = false;

  final TripRepository _tripRepository = TripRepository();

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive != widget.isActive && widget.isActive) {
      getLocation();
    }
  }

  Future<void> getLocation() async {
    try {
      if (_startMapRoute) {
        return;
      }

      setState(() {
        _isLoading = true;
        _errMessage = "";
      });

      final Map<String, dynamic> res = await MapService.isPermissionGranted();
      if (!mounted) return;
      if (!res['status']) {
        setState(() {
          _errMessage =
              res['message'] ??
              "Something went wrong while checking location permissions.";
        });
        return;
      }

      Position position = await MapService.getCurrentPosition();
      SearchResult? location = await MapService.retrieveAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (location == null) {
        return;
      }

      setState(() {
        _currentLocationQuery = location;
        _currentLocationString = location.locationString!;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errMessage = "Error fetching current location: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchAddresses(String? current, String? destination) async {
    if (current == null ||
        destination == null ||
        current.isEmpty ||
        destination.isEmpty) {
      setState(() {
        _errMessage = "Current and destination locations cannot be empty.";
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final searchResult = await MapService.queryPlaces(current, destination);

      if (!mounted) return;

      setState(() {
        _currentLocations = searchResult.currentLocationResults;
        _destinationLocations = searchResult.destinationLocationResults;
      });
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
      setState(() {
        _errMessage = "Error fetching addresses";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void resetState() {
    setState(() {
      _startMapRoute = false;
      _currentLocationSelected = false;
      _destinationLocationSelected = false;
      _currentLocations = [];
      _destinationLocations = [];
      _destinationLocationQuery = null;
      _currentLocationQuery = null;
      _currentLocationString = "";
      _destinationLocationString = "";
      _currentTripId = null;
      _selectedMode = null;
      _totalDistanceKm = null;
      _estimatedTimeMinutes = null;
    });
  }

  double _calculateTime(double distanceKm, TransportModes mode) {
    final speed = switch (mode) {
      TransportModes.walk => 5.0,
      TransportModes.run => 8.0,
      TransportModes.bike => 15.0,
    };
    return (distanceKm / speed) * 60; // minutes
  }

  Future<void> _startTrip(ComparisonTransportMode comparisonMode) async {
    if (_selectedMode == null || _totalDistanceKm == null) return;

    setState(() {
      _isStartingTrip = true;
    });

    try {
      int id = await _tripRepository.startTrip(
        Trip(
          date: DateTime.now(),
          distance: _totalDistanceKm!,
          transportMode: _selectedMode!.name,
          carbonSaved: CarbonCalculator.emissionSaved(
            comparisonMode,
            _totalDistanceKm!,
          ),
        ),
      );

      if (!mounted) return;

      final t = await ref.read(tripProvider.notifier).loadTrips();
      debugPrint("trips loaded ${t.length}");

      if (!mounted) return;

      setState(() {
        _currentTripId = id;
        _startMapRoute = true;
      });
    } catch (e) {
      debugPrint("Error starting trip: $e");
      if (!mounted) return;
      setState(() {
        _errMessage = "Error starting trip: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingTrip = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User data not available")),
      );
    }

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
                    Positioned.fill(
                      child:
                          _startMapRoute &&
                              _currentLocationQuery != null &&
                              _destinationLocationQuery != null
                          ? MapUI(
                              currentLat: _currentLocationQuery!.lat!,
                              currentLon: _currentLocationQuery!.lon!,
                              destinationLat: _destinationLocationQuery!.lat!,
                              destinationLon: _destinationLocationQuery!.lon!,
                              type: getRoadType(_selectedMode!),
                            )
                          : Opacity(
                              opacity: 0.7,
                              child: Image.asset(
                                'assets/images/map_placeholder.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),

                    if (_startMapRoute)
                      Positioned(
                        top: topPadding + size.height * 0.02,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.directions,
                                  color: AppColors.primaryColor,
                                  size: 30,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  showMapModal(
                                    context,
                                    "Trip Information",
                                    _totalDistanceKm!,
                                    _currentLocationQuery!.locationString!,
                                    _destinationLocationQuery!.locationString!,
                                    () async {
                                      await _tripRepository.cancelTrip(
                                        _currentTripId!,
                                      );
                                      await ref
                                          .read(tripProvider.notifier)
                                          .loadTrips();
                                      resetState();
                                    },
                                    () {
                                      resetState();
                                    },
                                  );
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Calculating route for ${_destinationLocationQuery!.locationString}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.primaryColor,
                                          overflow: TextOverflow.ellipsis,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Positioned(
                        top: topPadding + size.height * 0.01,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LocationCard(
                                currentLocation: _currentLocationQuery,
                                onCurrentSelection: (SearchResult value) {
                                  setState(() {
                                    _currentLocations = [];
                                    _currentLocationSelected = true;
                                    _currentLocationQuery = value;
                                    _selectedMode = null;
                                    _totalDistanceKm = null;
                                    _estimatedTimeMinutes = null;
                                  });
                                },
                                currentLocations: _currentLocations,
                                destinationLocations: _destinationLocations,
                                onDestinationSelection: (SearchResult value) {
                                  setState(() {
                                    _destinationLocations = [];
                                    _destinationLocationSelected = true;
                                    _destinationLocationQuery = value;
                                    _selectedMode = null;
                                    _totalDistanceKm = null;
                                    _estimatedTimeMinutes = null;
                                  });
                                },

                                onCurrentChanged: (String value) {
                                  setState(() {
                                    _currentLocationString = value;
                                  });
                                },
                                onDestinationChanged: (String value) {
                                  setState(() {
                                    _destinationLocationString = value;
                                  });
                                },
                              ),
                              if (_currentLocationSelected &&
                                  _destinationLocationSelected) ...[
                                SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),

                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,

                                    children: [
                                      Text(
                                        "Choose a mode of transportation",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.subtitleText,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Wrap(
                                        runSpacing: 4,
                                        spacing: 6,
                                        alignment: WrapAlignment.center,
                                        children: List.generate(
                                          TransportModes.values.length,
                                          (i) => ElevatedButton(
                                            onPressed: () {
                                              double distanceKm =
                                                  MapService.calculateDistanceInKm(
                                                    startLatitude:
                                                        _currentLocationQuery!
                                                            .lat!,
                                                    startLongitude:
                                                        _currentLocationQuery!
                                                            .lon!,
                                                    endLatitude:
                                                        _destinationLocationQuery!
                                                            .lat!,
                                                    endLongitude:
                                                        _destinationLocationQuery!
                                                            .lon!,
                                                  );

                                              final mode =
                                                  TransportModes.values[i];

                                              setState(() {
                                                _selectedMode = mode;
                                                _totalDistanceKm = distanceKm;
                                                _estimatedTimeMinutes =
                                                    _calculateTime(
                                                      distanceKm,
                                                      mode,
                                                    );
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _selectedMode ==
                                                      TransportModes.values[i]
                                                  ? AppColors
                                                        .selectedOptionColor
                                                        .withValues(alpha: 0.5)
                                                  : AppColors
                                                        .metricsBackgroundColor,
                                              foregroundColor:
                                                  AppColors.secondaryColor,
                                              shadowColor: Colors.transparent,
                                              side: BorderSide(
                                                color: AppColors.secondaryColor
                                                    .withValues(alpha: 0.4),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 2,
                                              ),
                                            ),
                                            child: Text(
                                              TransportModes.values[i].name,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_selectedMode != null) ...[
                                        SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Estimated Carbon Saved ☘️: ${(CarbonCalculator.emissionSaved(user.comparisonMode, _totalDistanceKm!) / 1000).toStringAsFixed(2)} kg",
                                            style: TextStyle(
                                              color: AppColors.subtitleText,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Estimated Time Taken ⏱️: ${_estimatedTimeMinutes!.toStringAsFixed(0)} min",
                                            style: TextStyle(
                                              color: AppColors.subtitleText,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 14),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: ElevatedButton(
                                            onPressed: _isStartingTrip
                                                ? null
                                                : () => _startTrip(
                                                    user.comparisonMode,
                                                  ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors
                                                  .selectedOptionColor
                                                  .withValues(alpha: 0.5),
                                              foregroundColor:
                                                  AppColors.secondaryColor,
                                              shadowColor: Colors.transparent,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10,
                                              ),
                                              side: BorderSide(
                                                color: AppColors.secondaryColor
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: _isStartingTrip
                                                ? SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Text("Continue to route"),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (_selectedMode == null)
                      Positioned(
                        bottom: size.height * 0.05,
                        right: 20,
                        child: LocateButton(
                          onPressed:
                              _currentLocationString.isNotEmpty &&
                                  _destinationLocationString.isNotEmpty
                              ? () {
                                  fetchAddresses(
                                    _currentLocationString,
                                    _destinationLocationString,
                                  );
                                }
                              : null,
                          isLoading: _isLoading,
                          isShowingMap: _startMapRoute,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
