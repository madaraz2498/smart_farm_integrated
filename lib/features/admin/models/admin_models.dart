// Admin dashboard + user management models
// GET /admin/dashboard/stats
// GET /admin/users/summary-and-list

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
    // Support optional {"data": {...}} wrapper
    final j = json['data'] is Map ? json['data'] as Map<String, dynamic> : json;
    return DashboardStats(
      totalAnalyses: _i(j['total_analyses'] ?? j['analyses_count'] ?? 0),
      totalUsers: _i(j['total_users'] ?? j['users_count'] ?? 0),
      activeUsers: _i(j['active_users'] ?? j['active_count'] ?? 0),
      totalAdmins: _i(j['total_admins'] ?? j['admins_count'] ?? 0),
      aiServicesOnline:
          _i(j['ai_services_online'] ?? j['active_services'] ?? 6),
      mostUsedService: j['most_used_service'] as String? ??
          j['top_service'] as String? ??
          'Plant Disease',
      analysesGrowth: j['analyses_growth'] as String? ?? '+0%',
      usersGrowth: j['users_growth'] as String? ?? '+0%',
    );
  }

  final int totalAnalyses,
      totalUsers,
      activeUsers,
      totalAdmins,
      aiServicesOnline;
  final String mostUsedService;
  final String? analysesGrowth, usersGrowth;

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

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: (j['id'] ?? j['user_id'] ?? 0).toString(),
        username: j['username'] as String? ?? j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? true,
        role: j['role'] as String? ?? 'Farmer',
        isAdmin: j['is_admin'] as bool? ?? false,
        profileImg: j['profile_img'] as String?,
        createdAt: j['created_at'] as String?,
      );

  final String id, username, email, role;
  final bool isActive, isAdmin;
  final String? profileImg;
  final String? createdAt;

  String get displayName =>
      username.isNotEmpty ? username : email.split('@').first;
  String get displayRole => isAdmin ? 'Admin' : role;
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

// ── helpers ───────────────────────────────────────────────────────────────────

int _i(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
