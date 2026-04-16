// lib/features/notifications/services/notification_service.dart

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient.instance;

  // GET /notifications/notifications/my-notifications/{user_id}
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final response = await _apiClient
          .get('/notifications/notifications/my-notifications/$userId');
      if (response is List) {
        return response
            .map((json) =>
            AppNotification.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      if (response is Map && response['notifications'] is List) {
        return (response['notifications'] as List)
            .map((json) =>
            AppNotification.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[NotificationService] getNotifications error: $e');
      return [];
    }
  }

  // PATCH /notifications/notifications/read/{notif_id}
  Future<bool> markAsRead(String notifId) async {
    try {
      await _apiClient.patch('/notifications/notifications/read/$notifId');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] markAsRead error: $e');
      return false;
    }
  }

  // PATCH /notifications/notifications/read-all/{user_id}
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _apiClient.patch('/notifications/notifications/read-all/$userId');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] markAllAsRead error: $e');
      return false;
    }
  }

  // DELETE /notifications/notifications/delete/{notif_id}
  Future<bool> deleteNotification(String notifId) async {
    try {
      await _apiClient
          .delete('/notifications/notifications/delete/$notifId');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] deleteNotification error: $e');
      return false;
    }
  }

  // DELETE /notifications/notifications/delete-all/{user_id}
  Future<bool> deleteAll(String userId) async {
    try {
      await _apiClient
          .delete('/notifications/notifications/delete-all/$userId');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] deleteAll error: $e');
      return false;
    }
  }

  // Backwards-compatible alias (older call sites).
  Future<bool> deleteAllNotifications(String userId) => deleteAll(userId);

  // GET /notifications/notifications/get-settings/{user_id}
  Future<FarmerNotificationSettings?> getFarmerSettings(String userId) async {
    try {
      final response = await _apiClient
          .get('/notifications/notifications/get-settings/$userId');
      if (response is Map<String, dynamic>) {
        return FarmerNotificationSettings.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('[NotificationService] getFarmerSettings error: $e');
      return null;
    }
  }

  // PATCH /notifications/notifications/farmer-settings/{user_id}
  Future<bool> updateFarmerSettings(
      String userId, FarmerNotificationSettings settings) async {
    try {
      await _apiClient.patch(
        '/notifications/notifications/farmer-settings/$userId',
        body: settings.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] updateFarmerSettings error: $e');
      return false;
    }
  }

  // PATCH /notifications/notifications/admin-settings/{user_id}
  Future<bool> updateAdminSettings(
      String userId, AdminNotificationSettings settings) async {
    try {
      await _apiClient.patch(
        '/notifications/notifications/admin-settings/$userId',
        body: settings.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] updateAdminSettings error: $e');
      return false;
    }
  }
}