class FarmerDashboardData {
  const FarmerDashboardData({
    required this.totalAnalyses,
    required this.todayAnalyses,
    required this.mostUsedService,
    required this.weather,
    this.weatherTemp,
    this.weatherHumidity,
    this.weatherWind,
    this.weatherDescription,
    this.locationName,
  });

  factory FarmerDashboardData.fromJson(Map<String, dynamic> j) {
    final stats = j['statistics'] as Map<String, dynamic>? ?? {};
    final weatherMap = j['weather'] as Map<String, dynamic>? ?? {};

    // Create a user-friendly weather string or pick a specific field
    final temp = weatherMap['temp'] as String? ?? '';
    final desc = weatherMap['desc'] as String? ?? '';
    final humidity = weatherMap['humidity']?.toString();
    final wind = weatherMap['wind']?.toString() ?? weatherMap['wind_speed']?.toString();
    final location = weatherMap['location'] as String?;
    final weatherStr = (temp.isNotEmpty && desc.isNotEmpty)
        ? '$temp - $desc'
        : (temp.isNotEmpty ? temp : (desc.isNotEmpty ? desc : 'N/A'));

    return FarmerDashboardData(
      totalAnalyses: _i(stats['total'] ?? 0),
      todayAnalyses: _i(stats['today'] ?? 0),
      mostUsedService: stats['most_used'] as String? ?? 'N/A',
      weather: weatherStr,
      weatherTemp: temp.isEmpty ? null : temp,
      weatherHumidity: humidity,
      weatherWind: wind,
      weatherDescription: desc.isEmpty ? null : desc,
      locationName: location,
    );
  }

  final int totalAnalyses;
  final int todayAnalyses;
  final String mostUsedService;
  final String weather;
  final String? weatherTemp;
  final String? weatherHumidity;
  final String? weatherWind;
  final String? weatherDescription;
  final String? locationName;

  Map<String, dynamic> toJson() {
    return {
      'total_analyses': totalAnalyses,
      'today_analyses': todayAnalyses,
      'most_used_service': mostUsedService,
      'weather': weather,
      'weather_temp': weatherTemp,
      'weather_humidity': weatherHumidity,
      'weather_wind': weatherWind,
      'weather_description': weatherDescription,
      'location_name': locationName,
    };
  }
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
