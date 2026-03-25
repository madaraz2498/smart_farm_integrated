// lib/features/admin/reports/models/report_model.dart

class ServiceUsage {
  final String service;
  final int count;

  ServiceUsage({required this.service, required this.count});

  factory ServiceUsage.fromJson(String service, dynamic count) {
    return ServiceUsage(
      service: service,
      count: (count as num).toInt(),
    );
  }
}

class UserGrowth {
  final String month;
  final int users;

  UserGrowth({required this.month, required this.users});

  factory UserGrowth.fromJson(String month, dynamic users) {
    return UserGrowth(
      month: month,
      users: (users as num).toInt(),
    );
  }
}

class DailyActivity {
  final String day;
  final int activity;

  DailyActivity({required this.day, required this.activity});

  factory DailyActivity.fromJson(String day, dynamic activity) {
    return DailyActivity(
      day: day,
      activity: (activity as num).toInt(),
    );
  }
}

class DashboardStats {
  final int totalAnalyses;
  final int activeUsers;
  final String aiServicesCount;
  final String avgResponseTime;
  final List<ServiceUsage> usageByService;
  final List<UserGrowth> userGrowth;
  final List<DailyActivity> dailyActivity;

  DashboardStats({
    required this.totalAnalyses,
    required this.activeUsers,
    required this.aiServicesCount,
    required this.avgResponseTime,
    required this.usageByService,
    required this.userGrowth,
    required this.dailyActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final charts = json['charts'] as Map<String, dynamic>? ?? {};

    return DashboardStats(
      totalAnalyses: (json['total_analyses'] as num? ?? 0).toInt(),
      activeUsers: (json['active_users'] as num? ?? 0).toInt(),
      aiServicesCount: json['ai_services_count'] as String? ?? '0',
      avgResponseTime: json['avg_response_time'] as String? ?? '0s',
      usageByService: _mapToServiceUsage(charts['usage_by_service']),
      userGrowth: _mapToUserGrowth(charts['user_growth']),
      dailyActivity: _mapToDailyActivity(charts['daily_activity']),
    );
  }

  static List<ServiceUsage> _mapToServiceUsage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.entries
          .map((e) => ServiceUsage.fromJson(e.key, e.value))
          .toList();
    }
    return [];
  }

  static List<UserGrowth> _mapToUserGrowth(dynamic data) {
    final monthsOrder = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final currentMonthIndex = DateTime.now().month - 1; // 0-based
    final Map<String, int> growthMap = {};

    // Initialize all months up to current with 0
    for (int i = 0; i <= currentMonthIndex; i++) {
      growthMap[monthsOrder[i]] = 0;
    }

    // Overlay API data if available
    if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        final cleanKey = key.trim();
        // Match case-insensitive short month names
        final index = monthsOrder.indexWhere(
            (m) => m.toLowerCase() == cleanKey.toLowerCase().substring(0, 3));
        if (index >= 0 && index <= currentMonthIndex) {
          growthMap[monthsOrder[index]] = (value as num).toInt();
        }
      });
    }

    // Convert map to sorted list
    final List<UserGrowth> result = [];
    for (int i = 0; i <= currentMonthIndex; i++) {
      result.add(
          UserGrowth(month: monthsOrder[i], users: growthMap[monthsOrder[i]]!));
    }

    return result;
  }

  static List<DailyActivity> _mapToDailyActivity(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.entries
          .map((e) => DailyActivity.fromJson(e.key, e.value))
          .toList();
    }
    return [];
  }
}
