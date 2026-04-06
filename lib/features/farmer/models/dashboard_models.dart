class FarmerDashboardData {
  const FarmerDashboardData({
    required this.totalAnalyses,
    required this.todayAnalyses,
    required this.mostUsedService,
    required this.weather,
    this.locationName,
  });

  factory FarmerDashboardData.fromJson(Map<String, dynamic> j) {
    final stats = j['statistics'] as Map<String, dynamic>? ?? {};
    final weatherMap = j['weather'] as Map<String, dynamic>? ?? {};

    // Create a user-friendly weather string or pick a specific field
    final temp = weatherMap['temp'] as String? ?? '';
    final desc = weatherMap['desc'] as String? ?? '';
    final location = weatherMap['location'] as String?;
    final weatherStr = (temp.isNotEmpty && desc.isNotEmpty)
        ? '$temp - $desc'
        : (temp.isNotEmpty ? temp : (desc.isNotEmpty ? desc : 'N/A'));

    return FarmerDashboardData(
      totalAnalyses: _i(stats['total'] ?? 0),
      todayAnalyses: _i(stats['today'] ?? 0),
      mostUsedService: stats['most_used'] as String? ?? 'N/A',
      weather: weatherStr,
      locationName: location,
    );
  }

  final int totalAnalyses;
  final int todayAnalyses;
  final String mostUsedService;
  final String weather;
  final String? locationName;
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
