import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/production_logger.dart';
import '../models/admin_models.dart';

// Top-level parsers for compute() — keep heavy JSON off the main thread.
DashboardStats _parseDashboardStats(dynamic raw) {
  return DashboardStats.fromJson(_ApiParser.parseAsMap(raw));
}

UserManagementData _parseUserManagementData(dynamic raw) {
  return UserManagementData.fromJson(_ApiParser.parseAsMap(raw));
}

/// Helper methods for robust API response parsing
class _ApiParser {
  /// Safely parse a response that could be either a Map or List
  /// Returns a Map if possible, otherwise empty Map
  static Map<String, dynamic> parseAsMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  /// Safely parse a response that could be either a List or Map containing a list
  /// Returns a List if possible, otherwise empty List
  static List<T> parseAsList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map) {
      // Check for common list container keys
      for (final key in ['data', 'users', 'results', 'items']) {
        if (data[key] is List) {
          return (data[key] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    }
    return [];
  }
}

/// All admin API endpoints — corrected paths (no doubled prefixes).
///
/// ── Dashboard ──────────────────────────────────────────────────────────────
///   GET  /admin/dashboard/stats
///
/// ── Users ──────────────────────────────────────────────────────────────────
///   GET    /admin/users/summary-and-list
///   GET    /admin/users/search?query=
///   DELETE /admin/users/delete/{user_id}
///   PATCH  /admin/users/deactivate/{user_id}
///   PATCH  /admin/users/activate/{user_id}
///   POST   /admin/users/promote-to-admin       query: { "email": "..." }
///   POST   /admin/users/promote-to-super-admin  query: { "email": "..." }
///   POST   /admin/users/demote-to-farmer        query: { "email": "..." }
///   PATCH  /admin/users/change-role/{user_id}   body: { "role": "..." }
///   GET    /admin/users/roles-summary
///   PATCH  /admin/users/settings/notifications/{user_id}
///
///   PATCH  /notifications/notifications/admin-settings/{user_id}
///
/// ── System ─────────────────────────────────────────────────────────────────
///   GET    /admin/system/admin/system/status
///   GET    /admin/system/admin/system/settings
///   POST   /admin/system/admin/system/settings/toggle/{setting_name}
///   POST   /admin/system/toggle-service/{module_name}
///   GET    /admin/system/models-table
///
/// ── Reports ────────────────────────────────────────────────────────────────
///   GET    /admin/reports/admin/reports/dashboard-stats
///   POST   /admin/reports/admin/reports/generate-pdf     body: { "period": "...", "format": "..." }
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();
  final ApiClient _c = ApiClient.instance;

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<DashboardStats> getDashboardStats() async {
    const path = '/admin/dashboard/stats';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getDashboardStats response: $data');
      return await compute(_parseDashboardStats, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('load_dashboard_statistics', e);
      throw ApiException('Failed to load dashboard statistics.');
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<UserManagementData> getUsersAndSummary() async {
    const path = '/admin/users/summary-and-list';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getUsersAndSummary response: $data');
      return await compute(_parseUserManagementData, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('load_user_data', e);
      throw ApiException('Failed to load user data.');
    }
  }

  Future<List<AdminUser>> searchUsers(String query) async {
    ProductionLogger.info('GET /admin/users/search?query=$query');
    try {
      final data = await _c.get('/admin/users/search', query: {'query': query});
      ProductionLogger.info('searchUsers response: $data');
      return _ApiParser.parseAsList<AdminUser>(data, AdminUser.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('search_failed', e);
      throw ApiException('Search failed.');
    }
  }

  Future<void> deleteUser(String userId) async {
    ProductionLogger.info('DELETE /admin/users/delete/$userId');
    try {
      await _c.delete('/admin/users/delete/$userId');
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('delete_user', e);
      throw ApiException('Failed to delete user.');
    }
  }

  Future<void> deactivateUser(String userId) async {
    ProductionLogger.info('PATCH /admin/users/deactivate/$userId');
    try {
      await _c.patch('/admin/users/deactivate/$userId');
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('deactivate_user', e);
      throw ApiException('Failed to deactivate user.');
    }
  }

  Future<void> activateUser(String userId) async {
    ProductionLogger.info('PATCH /admin/users/activate/$userId');
    try {
      await _c.patch('/admin/users/activate/$userId');
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('activate_user', e);
      throw ApiException('Failed to activate user.');
    }
  }

  Future<void> promoteToAdmin(String email) async {
    const path = '/admin/users/promote-to-admin';
    ProductionLogger.info('POST $path  query: {email: $email}');
    try {
      await _c.post(path, query: {'email': email});
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('promote_user', e);
      throw ApiException('Failed to promote user.');
    }
  }

  Future<void> promoteToSuperAdmin(String email) async {
    const path = '/admin/users/promote-to-super-admin';
    ProductionLogger.info('POST $path  query: {email: $email}');
    try {
      await _c.post(path, query: {'email': email});
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('promote_to_super_admin', e);
      throw ApiException('Failed to promote user to super admin.');
    }
  }

  Future<void> demoteToFarmer(String email) async {
    const path = '/admin/users/demote-to-farmer';
    ProductionLogger.info('POST $path  query: {email: $email}');
    try {
      await _c.post(path, query: {'email': email});
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('demote_user', e);
      throw ApiException('Failed to demote user.');
    }
  }

  Future<void> changeUserRole(String userId, String newRole) async {
    final path = '/admin/users/change-role/$userId';
    ProductionLogger.info('PATCH $path  body: {role: $newRole}');
    try {
      await _c.patch(path, body: {'role': newRole});
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('change_user_role', e);
      throw ApiException('Failed to change user role.');
    }
  }

  Future<Map<String, dynamic>> getRolesSummary() async {
    const path = '/admin/users/roles-summary';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getRolesSummary response: $data');
      return _ApiParser.parseAsMap(data);
    } catch (e) {
      ProductionLogger.error('get_roles_summary', e);
      throw ApiException('Failed to get roles summary.');
    }
  }

  Future<void> updateNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    final path = '/admin/users/settings/notifications/$userId';
    ProductionLogger.info('PATCH $path  body: $settings');
    try {
      await _c.patch(path, body: settings);
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('update_notification_settings', e);
      throw ApiException('Failed to update notification settings.');
    }
  }

  Future<void> updateAdminNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    final path = '/notifications/notifications/admin-settings/$userId';
    ProductionLogger.info('PATCH $path  body: $settings');
    try {
      await _c.patch(path, body: settings);
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('update_admin_notification_settings', e);
      throw ApiException('Failed to update admin notification settings.');
    }
  }

  // ── System ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSystemStatus() async {
    const path = '/admin/system/admin/system/status';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getSystemStatus response: $data');
      return _ApiParser.parseAsMap(data);
    } catch (e) {
      ProductionLogger.info('getSystemStatus non-critical: $e');
      return {};
    }
  }

  Future<List<SystemSetting>> getSystemSettings() async {
    const path = '/admin/system/admin/system/settings';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getSystemSettings response: $data');
      
      return _ApiParser.parseAsList<SystemSetting>(data, SystemSetting.fromJson);
    } catch (e) {
      ProductionLogger.info('getSystemSettings non-critical: $e');
      return [];
    }
  }

  Future<void> toggleSystemSetting(String settingName) async {
    final path = '/admin/system/admin/system/settings/toggle/$settingName';
    ProductionLogger.info('POST $path');
    try {
      await _c.post(path);
    } catch (e) {
      ProductionLogger.info('toggleSetting non-critical: $e');
    }
  }

  Future<Map<String, dynamic>> toggleService(String moduleName) async {
    final path = '/admin/system/toggle-service/$moduleName';
    ProductionLogger.info('POST $path');
    try {
      final r = await _c.post(path);
      return r is Map<String, dynamic> ? r : {};
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('toggle_service', e);
      throw ApiException('Failed to toggle service.');
    }
  }

  Future<List<Map<String, dynamic>>> getModelsTable() async {
    const path = '/admin/system/models-table';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getModelsTable response: $data');
      return _ApiParser.parseAsList<Map<String, dynamic>>(data, (json) => json);
    } catch (e) {
      ProductionLogger.info('getModelsTable non-critical: $e');
    }
    return [];
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminReportStats() async {
    const path = '/admin/reports/admin/reports/dashboard-stats';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getAdminReportStats response: $data');
      return _ApiParser.parseAsMap(data);
    } catch (e) {
      ProductionLogger.info('getAdminReportStats non-critical: $e');
      return {};
    }
  }

  Future<void> generatePdfReport({
    String period = 'Last 7 Days',
    String format = 'PDF',
  }) async {
    const path = '/admin/reports/admin/reports/generate-pdf';
    final body = {'period': period, 'format': format};
    ProductionLogger.info('POST $path  body: $body');
    try {
      await _c.post(path, body: body);
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.error('generate_pdf_report', e);
      throw ApiException('Failed to generate PDF report.');
    }
  }
}
