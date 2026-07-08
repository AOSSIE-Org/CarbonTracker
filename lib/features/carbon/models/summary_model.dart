class WeeklyData {
  final double carbonEmitted;
  final double carbonSaved;

  const WeeklyData({this.carbonEmitted = 0, this.carbonSaved = 0});
}

class Summary {
  final double totalCarbonEmitted;
  final double totalCarbonSaved;
  final double todayCarbonEmitted;
  final Map<String, WeeklyData> summaryData;

  Summary({
    required this.totalCarbonEmitted,
    required this.totalCarbonSaved,
    required this.todayCarbonEmitted,
    required this.summaryData,
  });
}
