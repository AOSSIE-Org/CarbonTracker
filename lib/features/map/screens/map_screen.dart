import 'dart:async';

import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/core/enums/comparison_modes.dart';
import 'package:carbon_tracker/core/enums/transport_modes.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/core/widgets/app_snackbar.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/features/carbon/helpers/carbon_calculator.dart';
import 'package:carbon_tracker/features/map/helpers/time_calculator.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/repositories/trip_repository.dart';
import 'package:carbon_tracker/features/map/services/location_service.dart';
import 'package:carbon_tracker/features/map/widgets/location_card.dart';
import 'package:carbon_tracker/features/map/widgets/map_modal.dart';
import 'package:carbon_tracker/features/map/widgets/map_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

typedef MapUiBuilder =
    Widget Function({
      required double currentLat,
      required double currentLon,
      required double destinationLat,
      required double destinationLon,
      required RoadType type,
    });

class MapScreen extends ConsumerStatefulWidget {
  final MapService mapOb;
  final TripRepository tripRepo;
  final MapUiBuilder mapUiBuilder;

  MapScreen({
    super.key,
    this.mapOb = const MapService(),
    TripRepository? tripRepo,
    MapUiBuilder? mapUiBuilder,
  }) : tripRepo = tripRepo ?? TripRepository(),
       mapUiBuilder = mapUiBuilder ?? MapUI.new;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _errMessage = "";
  SearchResult? _startLocation;
  SearchResult? _destinationLocation;
  List<SearchResult?> _startLocationSuggestions = [];
  List<SearchResult?> _destinationLocationSuggestions = [];
  bool _isStartLocationSelected = false;
  bool _isDestinationLocationSelected = false;
  TransportModes? _selectedTransportMode;
  bool _startMapRoute = false;
  int? _currentTripId;
  double? _totalDistanceKm;
  double? _estimatedTimeMinutes;
  bool _isLocating = false;
  bool _isStartingTrip = false;

  Timer? _debounceTimer;
  int _searchEpoch = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> getLocation() async {
    try {
      if (_startMapRoute) {
        return;
      }

      setState(() {
        _isLocating = true;
        _errMessage = "";
      });

      final Map<String, dynamic> res = await widget.mapOb.isPermissionGranted();
      if (!mounted) return;
      if (!res['status']) {
        _handleLocationUnavailable(res);
        return;
      }

      Position position = await widget.mapOb.getCurrentPosition();
      SearchResult? location = await widget.mapOb
          .retrieveAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );

      if (!mounted) return;

      if (location == null) {
        return;
      }

      _selectStartLocation(location);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errMessage = "Error fetching current location: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _handleLocationUnavailable(Map<String, dynamic> res) {
    final reason = res['reason'] as String?;
    switch (reason) {
      case 'service_disabled':
        showAppSnackBar(
          context,
          message:
              'Location services are disabled. Enable GPS to detect your location.',
          actionLabel: 'Settings',
          onAction: Geolocator.openLocationSettings,
        );
      case 'permission_denied_forever':
        showAppSnackBar(
          context,
          message:
              'Location permission is permanently denied. Enable it in app settings.',
          actionLabel: 'Settings',
          onAction: Geolocator.openAppSettings,
        );
      default:
        showAppSnackBar(
          context,
          message:
              res['message'] as String? ??
              'Location permission is required to detect your current location.',
          actionLabel: 'Retry',
          onAction: getLocation,
        );
    }
  }

  void _onLocationInputChanged(String value, {required bool isStart}) {
    final trimmed = value.trim();
    setState(() {
      if (isStart) {
        if (_startLocation?.locationString?.trim() != trimmed) {
          _isStartLocationSelected = false;
          _startLocation = null;
          _selectedTransportMode = null;
        }
      } else {
        if (_destinationLocation?.locationString?.trim() != trimmed) {
          _isDestinationLocationSelected = false;
          _destinationLocation = null;
          _selectedTransportMode = null;
        }
      }
    });

    _debounceTimer?.cancel();

    // Immediately clear suggestions if input is blank
    if (trimmed.isEmpty) {
      setState(() {
        _startLocationSuggestions = [];
        _destinationLocationSuggestions = [];
      });
      return;
    }

    final currentEpoch = ++_searchEpoch;
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(trimmed, isStart: isStart, epoch: currentEpoch);
    });
  }

  Future<void> _executeSearch(
    String query, {
    required bool isStart,
    required int epoch,
  }) async {
    if (epoch != _searchEpoch || !mounted) return;

    try {
      setState(() {
        if (isStart) {
          _destinationLocationSuggestions = [];
        } else {
          _startLocationSuggestions = [];
        }
      });

      final results = await widget.mapOb.searchPlace(query);
      if (epoch != _searchEpoch || !mounted) return;

      setState(() {
        if (isStart) {
          _startLocationSuggestions = results;
        } else {
          _destinationLocationSuggestions = results;
        }
      });
    } catch (e) {
      debugPrint("Error searching locations: $e");
    }
  }

  void _selectStartLocation(SearchResult value) {
    FocusScope.of(context).unfocus();
    if (_isSameLocation(value, _destinationLocation)) {
      showAppSnackBar(
        context,
        message: 'Start and destination cannot be the same place.',
      );
      return;
    }

    setState(() {
      _startLocationSuggestions = [];
      _destinationLocationSuggestions = [];
      _isStartLocationSelected = true;
      _startLocation = value;
      _selectedTransportMode = null;
      _totalDistanceKm = null;
      _estimatedTimeMinutes = null;
    });
  }

  void _selectDestinationLocation(SearchResult value) {
    FocusScope.of(context).unfocus();
    if (_isSameLocation(_startLocation, value)) {
      showAppSnackBar(
        context,
        message: 'Start and destination cannot be the same place.',
      );
      return;
    }

    setState(() {
      _destinationLocationSuggestions = [];
      _startLocationSuggestions = [];
      _isDestinationLocationSelected = true;
      _destinationLocation = value;
      _selectedTransportMode = null;
      _totalDistanceKm = null;
      _estimatedTimeMinutes = null;
    });
  }

  bool _isSameLocation(SearchResult? a, SearchResult? b) {
    if (a == null || b == null) return false;
    if (a.lat != null &&
        b.lat != null &&
        a.lon != null &&
        b.lon != null &&
        (a.lat! - b.lat!).abs() < 0.0001 &&
        (a.lon! - b.lon!).abs() < 0.0001) {
      return true;
    }
    if (a.locationString != null &&
        b.locationString != null &&
        a.locationString!.trim().toLowerCase() ==
            b.locationString!.trim().toLowerCase()) {
      return true;
    }
    return false;
  }

  void resetState() {
    _debounceTimer?.cancel();
    setState(() {
      _startMapRoute = false;
      _isStartLocationSelected = false;
      _isDestinationLocationSelected = false;
      _startLocationSuggestions = [];
      _destinationLocationSuggestions = [];
      _destinationLocation = null;
      _startLocation = null;
      _currentTripId = null;
      _selectedTransportMode = null;
      _totalDistanceKm = null;
      _estimatedTimeMinutes = null;
    });
  }

  Future<void> _startTrip(ComparisonTransportMode comparisonMode) async {
    if (_selectedTransportMode == null || _totalDistanceKm == null) return;

    setState(() {
      _isStartingTrip = true;
    });

    try {
      int id = await widget.tripRepo.startTrip(
        Trip(
          date: DateTime.now(),
          distance: _totalDistanceKm!,
          transportMode: _selectedTransportMode!.name,
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
                              _startLocation?.lat != null &&
                              _startLocation?.lon != null &&
                              _destinationLocation?.lat != null &&
                              _destinationLocation?.lon != null
                          ? widget.mapUiBuilder(
                              currentLat: _startLocation!.lat!,
                              currentLon: _startLocation!.lon!,
                              destinationLat: _destinationLocation!.lat!,
                              destinationLon: _destinationLocation!.lon!,
                              type: getRoadType(_selectedTransportMode!),
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
                                    _startLocation!.locationString!,
                                    _destinationLocation!.locationString!,
                                    () async {
                                      await widget.tripRepo.cancelTrip(
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
                                        "Calculating route for ${_destinationLocation!.locationString}",
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
                                currentLocation: _startLocation,
                                currentLocations: _startLocationSuggestions,
                                destinationLocations:
                                    _destinationLocationSuggestions,
                                isLocating: _isLocating,
                                onLocatePressed: getLocation,
                                onCurrentSelection: _selectStartLocation,
                                onDestinationSelection:_selectDestinationLocation,
                                onCurrentChanged: (String value) {
                                  _onLocationInputChanged(value, isStart: true);
                                },
                                onDestinationChanged: (String value) {
                                  _onLocationInputChanged(
                                    value,
                                    isStart: false,
                                  );
                                },
                              ),
                              if (_isStartLocationSelected &&
                                  _isDestinationLocationSelected &&
                                  _startLocation != null &&
                                  _destinationLocation != null) ...[
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
                                              final start = _startLocation;
                                              final dest = _destinationLocation;

                                              if (start?.lat == null ||
                                                  start?.lon == null ||
                                                  dest?.lat == null ||
                                                  dest?.lon == null) {
                                                showAppSnackBar(
                                                  context,
                                                  message:
                                                      "Please select valid locations from the suggestions.",
                                                );
                                                return;
                                              }

                                              double distanceKm = widget.mapOb
                                                  .calculateDistanceInKm(
                                                    startLatitude: start!.lat!,
                                                    startLongitude: start.lon!,
                                                    endLatitude: dest!.lat!,
                                                    endLongitude: dest.lon!,
                                                  );

                                              final mode =
                                                  TransportModes.values[i];

                                              setState(() {
                                                _selectedTransportMode = mode;
                                                _totalDistanceKm = distanceKm;
                                                _estimatedTimeMinutes =
                                                    calculateTime(
                                                      distanceKm,
                                                      mode,
                                                    );
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _selectedTransportMode ==
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
                                      if (_selectedTransportMode != null) ...[
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
                  ],
                ),
              ),
            ),
    );
  }
}
