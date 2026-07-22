import 'package:carbon_tracker/features/map/models/search_results.dart';

class SearchOptions {
  List<SearchResult?> currentLocationResults;
  List<SearchResult?> destinationLocationResults;

  SearchOptions({
    required this.currentLocationResults,
    required this.destinationLocationResults,
  });
}
