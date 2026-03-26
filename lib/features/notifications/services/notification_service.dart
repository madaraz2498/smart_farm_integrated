// lib/features/notifications/services/notification_service.dart

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final response = await _apiClient.get('/notifications/$userId');
      if (response is List) {
        return response.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // If endpoint 404, we just return empty list to avoid noisy errors
      // and let local notifications handle the UI part.
      debugPrint('[NotificationService] getNotifications error (expected if backend missing): $e');
      return [];
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _apiClient.patch('/notifications/read/$id');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] markAsRead failed: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await _apiClient.delete('/notifications/$id');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] deleteNotification failed: $e');
      return false;
    }
  }

  Future<bool> updateNotificationSettings({
    required String userId,
    bool? push,
    bool? email,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (push != null) queryParams['push'] = push.toString();
      if (email != null) queryParams['email'] = email.toString();

      await _apiClient.patch(
        '/admin/users/settings/notifications/$userId',
        query: queryParams,
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Update Settings Error: $e');
      return false;
    }
  }
}
