import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/production_logger.dart';
import '../models/admin_models.dart';

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
///   POST   /admin/users/promote-to-admin   query: { "email": "..." }
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
      return DashboardStats.fromJson(data as Map<String, dynamic>);
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
      return UserManagementData.fromJson(data as Map<String, dynamic>);
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
      if (data is List) {
        return data
            .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map && data['users'] is List) {
        return (data['users'] as List)
            .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
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
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      ProductionLogger.info('getSystemStatus non-critical: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getSystemSettings() async {
    const path = '/admin/system/admin/system/settings';
    ProductionLogger.info('GET $path');
    try {
      final data = await _c.get(path);
      ProductionLogger.info('getSystemSettings response: $data');
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      ProductionLogger.info('getSystemSettings non-critical: $e');
      return {};
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
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['models'] is List) {
        return (data['models'] as List).cast<Map<String, dynamic>>();
      }
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
      return (data as Map<String, dynamic>?) ?? {};
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
