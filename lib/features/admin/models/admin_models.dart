// Admin dashboard + user management models
// GET /admin/dashboard/stats
// GET /admin/users/summary-and-list
// GET /admin/system/admin/system/settings

class DashboardStats {
  const DashboardStats({
    required this.totalAnalyses,
    required this.totalUsers,
    required this.activeUsers,
    this.totalAdmins = 0,
    required this.aiServicesOnline,
    required this.mostUsedService,
    this.analysesGrowth,
    this.usersGrowth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Support multiple common wrappers: "data", "summary", "statistics", or "stats"
    final j = json['data'] is Map
        ? json['data'] as Map<String, dynamic>
        : json['summary'] is Map
            ? json['summary'] as Map<String, dynamic>
            : json['statistics'] is Map
                ? json['statistics'] as Map<String, dynamic>
                : json['stats'] is Map
                    ? json['stats'] as Map<String, dynamic>
                    : json;

    return DashboardStats(
      totalAnalyses: _i(j['total_analyses'] ??
          j['analyses_count'] ??
          j['total'] ??
          j['analyses'] ??
          0),
      totalUsers: _i(j['total_users'] ??
          j['users_count'] ??
          j['users'] ??
          j['total_registered'] ??
          0),
      activeUsers: _i(j['active_users'] ??
          j['active_count'] ??
          j['active'] ??
          j['online_users'] ??
          0),
      totalAdmins:
          _i(j['total_admins'] ?? j['admins_count'] ?? j['admins'] ?? 0),
      aiServicesOnline: _i(j['ai_services_online'] ??
          j['active_services'] ??
          j['services_online'] ??
          6),
      mostUsedService: j['most_used_service'] as String? ??
          j['top_service'] as String? ??
          j['most_used'] as String? ??
          'Plant Disease',
      analysesGrowth: (j['analyses_growth'] ?? j['growth'] ?? '+0%').toString(),
      usersGrowth: (j['users_growth'] ?? j['user_growth'] ?? '+0%').toString(),
    );
  }

  final int totalAnalyses,
      totalUsers,
      activeUsers,
      totalAdmins,
      aiServicesOnline;
  final String mostUsedService;
  final String? analysesGrowth, usersGrowth;

  DashboardStats copyWith({
    int? totalAnalyses,
    int? totalUsers,
    int? activeUsers,
    int? totalAdmins,
    int? aiServicesOnline,
    String? mostUsedService,
    String? analysesGrowth,
    String? usersGrowth,
  }) {
    return DashboardStats(
      totalAnalyses: totalAnalyses ?? this.totalAnalyses,
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      totalAdmins: totalAdmins ?? this.totalAdmins,
      aiServicesOnline: aiServicesOnline ?? this.aiServicesOnline,
      mostUsedService: mostUsedService ?? this.mostUsedService,
      analysesGrowth: analysesGrowth ?? this.analysesGrowth,
      usersGrowth: usersGrowth ?? this.usersGrowth,
    );
  }

  String get formattedAnalyses => _fmt(totalAnalyses);
  String get formattedUsers => _fmt(totalUsers);
  String get aiServicesDisplay => '$aiServicesOnline / 6';

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class UserManagementData {
  const UserManagementData({
    required this.users,
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.inactiveUsers = 0,
  });

  factory UserManagementData.fromJson(Map<String, dynamic> json) {
    final j = json['data'] is Map ? json['data'] as Map<String, dynamic> : json;
    final raw = j['users'] is List
        ? j['users'] as List
        : j['data'] is List
            ? j['data'] as List
            : <dynamic>[];

    final users =
        raw.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();

    final s = j['summary'] is Map ? j['summary'] as Map<String, dynamic> : j;
    return UserManagementData(
      users: users,
      totalUsers: _i(s['total_users'] ?? users.length),
      activeUsers: _i(s['active_users'] ?? 0),
      inactiveUsers: _i(s['inactive_users'] ?? 0),
    );
  }

  final List<AdminUser> users;
  final int totalUsers, activeUsers, inactiveUsers;
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.isActive,
    this.role = 'Farmer',
    this.isAdmin = false,
    this.profileImg,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) {
    final rawActive = j['is_active'];
    final status = (j['status'] as String? ?? '').toLowerCase();
    final roleStr = (j['role'] as String? ?? '').toLowerCase();

    bool active = true;
    if (rawActive is bool) {
      active = rawActive;
    } else if (rawActive is int) {
      active = rawActive == 1;
    } else if (status == 'inactive' ||
        status == 'disabled' ||
        roleStr == 'inactive') {
      active = false;
    } else if (status == 'active') {
      active = true;
    }

    return AdminUser(
      id: (j['id'] ?? j['user_id'] ?? 0).toString(),
      username: j['username'] as String? ?? j['name'] as String? ?? '',
      email: j['email'] as String? ?? '',
      isActive: active,
      role: j['role'] as String? ?? 'Farmer',
      isAdmin: j['is_admin'] as bool? ?? false,
      profileImg: j['profile_img'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }

  final String id, username, email, role;
  final bool isActive, isAdmin;
  final String? profileImg;
  final String? createdAt;

  String get displayName =>
      username.isNotEmpty ? username : email.split('@').first;
  String get displayRole {
    final roleLower = role.toLowerCase();
    if (roleLower == 'super_admin') return 'Super Admin';
    if (isAdmin) return 'Admin';
    return role;
  }

  bool get isSuperAdmin => role.toLowerCase() == 'super_admin';
  String get statusLabel => isActive ? 'Active' : 'Inactive';

  AdminUser copyWith({bool? isActive}) => AdminUser(
        id: id,
        username: username,
        email: email,
        isActive: isActive ?? this.isActive,
        role: role,
        isAdmin: isAdmin,
        createdAt: createdAt,
      );
}

// Navigation item for admin sidebar
class AdminNavItem {
  const AdminNavItem(
      {required this.icon, required this.label, this.isAdminOnly = false});
  final Object icon; // IconData
  final String label;
  final bool isAdminOnly;
}

class SystemSetting {
  const SystemSetting({
    required this.key,
    required this.name,
    required this.status,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
    );
  }

  final String key;
  final String name;
  final String status;

  bool get isOnline => status.toLowerCase() == 'online';

  Map<String, bool> toSettingsMap() {
    return {key: isOnline};
  }
}

class UserActivity {
  final String date;
  final String activity;
  final String status;

  const UserActivity({
    required this.date,
    required this.activity,
    required this.status,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      date: json['date'] as String? ?? '',
      activity: json['activity'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class SystemStatus {
  final String status;
  final String uptime;
  final String responseTime;
  final String dbStatus;
  final String dbStorage;
  final int dbConnections;
  final String aiActive;
  final String aiAccuracy;
  final String aiRequests;

  const SystemStatus({
    required this.status,
    required this.uptime,
    required this.responseTime,
    required this.dbStatus,
    required this.dbStorage,
    required this.dbConnections,
    required this.aiActive,
    required this.aiAccuracy,
    required this.aiRequests,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final sys = json['system'] ?? {};
    final db = json['database'] ?? {};
    final ai = json['ai_models_summary'] ?? {};

    return SystemStatus(
      status: sys['status']?.toString() ?? 'Unknown',
      uptime: sys['uptime']?.toString() ?? '0h 0m',
      responseTime: sys['response_time']?.toString() ?? '0ms',
      dbStatus: db['status']?.toString() ?? 'Unknown',
      dbStorage: db['storage_used']?.toString() ?? '0 kB',
      dbConnections: (db['connections'] as num?)?.toInt() ?? 0,
      aiActive: ai['active']?.toString() ?? '0 / 0',
      aiAccuracy: ai['avg_accuracy']?.toString() ?? '0%',
      aiRequests: ai['total_requests']?.toString() ?? '0',
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────────

int _i(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
