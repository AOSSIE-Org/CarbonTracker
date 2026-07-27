import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/core/enums/transport_modes.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/database/models/trips.dart';
import 'package:carbon_tracker/features/carbon/helpers/carbon_calculator.dart';
import 'package:carbon_tracker/features/map/models/search_results.dart';
import 'package:carbon_tracker/features/map/repositories/trip_repository.dart';
import 'package:carbon_tracker/features/map/services/location_service.dart';
import 'package:carbon_tracker/features/map/widgets/location_button.dart';
import 'package:carbon_tracker/features/map/widgets/location_card.dart';
import 'package:carbon_tracker/features/map/widgets/map_modal.dart';
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
  bool _isLoading = false;
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

      Map res = await MapService.isPermissionGranted();
      if(!mounted) return;
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
    });
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
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.directions,
                                  color: AppColors.secondaryColor,
                                  size: 30,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Rectangular Container
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
                                    () async {
                                      resetState();
                                    },
                                  );
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
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
                                          color: AppColors.secondaryColor,
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
                                  });
                                },
                                currentLocations: _currentLocations,
                                destinationLocations: _destinationLocations,
                                onDestinationSelection: (SearchResult value) {
                                  setState(() {
                                    _destinationLocations = [];
                                    _destinationLocationSelected = true;
                                    _destinationLocationQuery = value;
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
                                            onPressed: () async {
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

                                              int
                                              id = await _tripRepository.startTrip(
                                                Trip(
                                                  date: DateTime.now(),
                                                  distance: distanceKm,
                                                  transportMode: TransportModes
                                                      .values[i]
                                                      .name,
                                                  carbonEmitted:
                                                      CarbonCalculator.emission(
                                                        TransportModes
                                                            .values[i],
                                                        distanceKm,
                                                      ),
                                                  carbonSaved:
                                                      CarbonCalculator.savings(
                                                        TransportModes
                                                            .values[i],
                                                        distanceKm,
                                                      ),
                                                ),
                                              );

                                              final t = await ref
                                                  .read(tripProvider.notifier)
                                                  .loadTrips();

                                              debugPrint(
                                                "trips loaded ${t.length}",
                                              );

                                              setState(() {
                                                _currentTripId = id;
                                                _selectedMode =
                                                    TransportModes.values[i];
                                                _startMapRoute = true;
                                                _totalDistanceKm = distanceKm;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors
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
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

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
