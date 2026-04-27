// lib/features/notifications/services/notification_service.dart
// ✅ FIX: Settings sent as query params (not JSON body) — matches API spec

import 'dart:async';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';
import '../../../core/utils/production_logger.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<T?> _safeCall<T>(Future<T> Function() request, String tag) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      ProductionLogger.notifications('[$tag] TIMEOUT');
      return null;
    } catch (e) {
      ProductionLogger.notifications('[$tag] ERROR: $e');
      return null;
    }
  }

  // ── GET notifications ────────────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications(String userId) async {
    final response = await _safeCall(
      () => _apiClient.get('/notifications/notifications/my-notifications/$userId'),
      'getNotifications',
    );
    if (response == null) return [];
    try {
      if (response is List) {
        return response.map((j) => AppNotification.fromJson(j)).toList();
      }
      if (response is Map && response['notifications'] is List) {
        return (response['notifications'] as List)
            .map((j) => AppNotification.fromJson(j))
            .toList();
      }
      return [];
    } catch (e) {
      ProductionLogger.notifications('parse error: $e');
      return [];
    }
  }

  // ── Mark read ────────────────────────────────────────────────────────────

  Future<bool> markAsRead(String notifId) async {
    final res = await _safeCall(
      () => _apiClient.patch('/notifications/notifications/read/$notifId'),
      'markAsRead',
    );
    return res != null;
  }

  Future<bool> markAllAsRead(String userId) async {
    final res = await _safeCall(
      () => _apiClient.patch('/notifications/notifications/read-all/$userId'),
      'markAllAsRead',
    );
    return res != null;
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<bool> deleteNotification(String notifId) async {
    final res = await _safeCall(
      () => _apiClient.delete('/notifications/notifications/delete/$notifId'),
      'deleteNotification',
    );
    return res != null;
  }

  Future<bool> deleteAllNotifications(String userId) async {
    final res = await _safeCall(
      () => _apiClient.delete('/notifications/notifications/delete-all/$userId'),
      'deleteAll',
    );
    return res != null;
  }

  // ── Settings GET ─────────────────────────────────────────────────────────

  Future<FarmerNotificationSettings?> getFarmerSettings(String userId) async {
    final response = await _safeCall(
      () => _apiClient.get('/notifications/notifications/get-settings/$userId'),
      'getFarmerSettings',
    );
    if (response is Map<String, dynamic>) {
      return FarmerNotificationSettings.fromJson(response);
    }
    return null;
  }

  Future<AdminNotificationSettings?> getAdminSettings(String userId) async {
    final response = await _safeCall(
      () => _apiClient.get('/notifications/notifications/get-settings/$userId'),
      'getAdminSettings',
    );
    if (response is Map<String, dynamic>) {
      return AdminNotificationSettings.fromJson(response);
    }
    return null;
  }

  // ── Settings UPDATE ──────────────────────────────────────────────────────
  // ✅ FIX: API expects query params, NOT JSON body
  // PATCH /notifications/farmer-settings/{id}?email_notif=bool&analysis_alt=bool&weekly_alt=bool

  Future<bool> updateFarmerSettings(
    String userId,
    FarmerNotificationSettings settings,
  ) async {
    final res = await _safeCall(
      () => _apiClient.patch(
        '/notifications/notifications/farmer-settings/$userId',
        query: {
          'email_notif': settings.emailNotificationsFarmer.toString(),
          'analysis_alt': settings.analysisCompletionAlerts.toString(),
          'weekly_alt': settings.weeklyReportSummary.toString(),
        },
      ),
      'updateFarmerSettings',
    );
    return res != null;
  }

  // PATCH /notifications/admin-settings/{id}?admin_push=bool&admin_email=bool
  Future<bool> updateAdminSettings(
    String userId,
    AdminNotificationSettings settings,
  ) async {
    final res = await _safeCall(
      () => _apiClient.patch(
        '/notifications/notifications/admin-settings/$userId',
        query: {
          'admin_push': settings.pushNotifications.toString(),
          'admin_email': settings.emailNotifications.toString(),
        },
      ),
      'updateAdminSettings',
    );
    return res != null;
  }
}
