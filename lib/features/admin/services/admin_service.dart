import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/admin_models.dart';

/// All admin API endpoints — corrected paths (no doubled prefixes).
///
/// ── Dashboard ──────────────────────────────────────────────────────────────
///   GET  /admin/dashboard/stats
///
/// ── Users ──────────────────────────────────────────────────────────────────
///   GET    /admin/users/summary-and-list
///   GET    /admin/users/search?q=
///   DELETE /admin/users/delete/{user_id}
///   PATCH  /admin/users/deactivate/{user_id}
///   PATCH  /admin/users/activate/{user_id}
///   POST   /admin/users/promote-to-admin   body: { "user_id": <int> }
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
    debugPrint('[AdminService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[AdminService] getDashboardStats response: $data');
      return DashboardStats.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Failed to load dashboard statistics.');
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<UserManagementData> getUsersAndSummary() async {
    const path = '/admin/users/summary-and-list';
    debugPrint('[AdminService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[AdminService] getUsersAndSummary response: $data');
      return UserManagementData.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Failed to load user data.');
    }
  }

  Future<List<AdminUser>> searchUsers(String query) async {
    debugPrint('[AdminService] GET /admin/users/search?q=$query');
    try {
      final data = await _c.get('/admin/users/search', query: {'q': query});
      debugPrint('[AdminService] searchUsers response: $data');
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
    } catch (_) {
      throw const ApiException('Search failed.');
    }
  }

  Future<void> deleteUser(String userId) async {
    debugPrint('[AdminService] DELETE /admin/users/delete/$userId');
    try {
      await _c.delete('/admin/users/delete/$userId');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Failed to delete user.');
    }
  }

  Future<void> deactivateUser(String userId) async {
    debugPrint('[AdminService] PATCH /admin/users/deactivate/$userId');
    try {
      await _c.patch('/admin/users/deactivate/$userId');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Failed to deactivate user.');
    }
  }

  Future<void> activateUser(String userId) async {
    debugPrint('[AdminService] PATCH /admin/users/activate/$userId');
    try {
      await _c.patch('/admin/users/activate/$userId');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Failed to activate user.');
    }
  }

  Future<void> promoteToAdmin(String userId) async {
    const path = '/admin/users/promote-to-admin';
    final body = {'user_id': int.tryParse(userId) ?? userId};
    debugPrint('[AdminService] POST $path  body: $body');
    try {
      await _c.post(path, body: body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Failed to promote user.');
    }
  }

  // ── System ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSystemStatus() async {
    const path = '/admin/system/admin/system/status';
    debugPrint('[AdminService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[AdminService] getSystemStatus response: $data');
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      debugPrint('[AdminService] getSystemStatus non-critical: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getSystemSettings() async {
    const path = '/admin/system/admin/system/settings';
    debugPrint('[AdminService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[AdminService] getSystemSettings response: $data');
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      debugPrint('[AdminService] getSystemSettings non-critical: $e');
      return {};
    }
  }

  Future<void> toggleSystemSetting(String settingName) async {
    final path = '/admin/system/admin/system/settings/toggle/$settingName';
    debugPrint('[AdminService] POST $path');
    try {
      await _c.post(path);
    } catch (e) {
      debugPrint('[AdminService] toggleSetting non-critical: $e');
    }
  }

  Future<void> toggleService(String moduleName) async {
    final path = '/admin/system/toggle-service/$moduleName';
    debugPrint('[AdminService] POST $path');
    try {
      await _c.post(path);
    } catch (e) {
      debugPrint('[AdminService] toggleService non-critical: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getModelsTable() async {
    const path = '/admin/system/models-table';
    debugPrint('[AdminService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[AdminService] getModelsTable response: $data');
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['models'] is List) {
        return (data['models'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[AdminService] getModelsTable non-critical: $e');
    }
    return [];
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminReportStats() async {
    const path = '/admin/reports/admin/reports/dashboard-stats';
    debugPrint('[AdminService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[AdminService] getAdminReportStats response: $data');
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      debugPrint('[AdminService] getAdminReportStats non-critical: $e');
      return {};
    }
  }

  Future<void> generatePdfReport({
    String period = 'Last 7 Days',
    String format = 'PDF',
  }) async {
    const path = '/admin/reports/admin/reports/generate-pdf';
    final body = {'period': period, 'format': format};
    debugPrint('[AdminService] POST $path  body: $body');
    try {
      await _c.post(path, body: body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Failed to generate PDF report.');
    }
  }
}
