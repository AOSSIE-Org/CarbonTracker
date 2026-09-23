class WeeklyData {
  final double carbonSaved;

  const WeeklyData({this.carbonSaved = 0});
}

class Summary {
  final double totalCarbonSaved;
  final Map<String, WeeklyData> summaryData;

  Summary({required this.totalCarbonSaved, required this.summaryData});
}
