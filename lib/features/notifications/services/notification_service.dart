// lib/features/notifications/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient.instance;

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  Future<T?> _safeCall<T>(Future<T> Function() request, String tag) async {
    try {
      return await request().timeout(
        const Duration(seconds: 15),
      );
    } on TimeoutException {
      ProductionLogger.notifications('[$tag] TIMEOUT');
      return null;
    } catch (e) {
      ProductionLogger.notifications('[$tag] ERROR: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // GET notifications
  // ─────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications(String userId) async {
    final response = await _safeCall(
          () => _apiClient.get(
        '/notifications/notifications/my-notifications/$userId',
      ),
      'getNotifications',
    );

    if (response == null) return [];

    try {
      if (response is List) {
        return response
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }

      if (response is Map && response['notifications'] is List) {
        return (response['notifications'] as List)
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      ProductionLogger.notifications('parse error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────

  Future<bool> markAsRead(String notifId) async {
    final res = await _safeCall(
          () => _apiClient.patch(
        '/notifications/notifications/read/$notifId',
      ),
      'markAsRead',
    );
    return res != null;
  }

  Future<bool> markAllAsRead(String userId) async {
    final res = await _safeCall(
          () => _apiClient.patch(
        '/notifications/notifications/read-all/$userId',
      ),
      'markAllAsRead',
    );
    return res != null;
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  Future<bool> deleteNotification(String notifId) async {
    final res = await _safeCall(
          () => _apiClient.delete(
        '/notifications/notifications/delete/$notifId',
      ),
      'deleteNotification',
    );
    return res != null;
  }

  Future<bool> deleteAll(String userId) async {
    final res = await _safeCall(
          () => _apiClient.delete(
        '/notifications/notifications/delete-all/$userId',
      ),
      'deleteAll',
    );
    return res != null;
  }

  Future<bool> deleteAllNotifications(String userId) =>
      deleteAll(userId);

  // ─────────────────────────────────────────────
  // SETTINGS
  // ─────────────────────────────────────────────

  Future<FarmerNotificationSettings?> getFarmerSettings(
      String userId) async {
    final response = await _safeCall(
          () => _apiClient.get(
        '/notifications/notifications/get-settings/$userId',
      ),
      'getFarmerSettings',
    );

    if (response is Map<String, dynamic>) {
      return FarmerNotificationSettings.fromJson(response);
    }

    return null;
  }

  Future<AdminNotificationSettings?> getAdminSettings(String userId) async {
    final response = await _safeCall(
          () => _apiClient.get(
        '/notifications/notifications/admin-settings/$userId',
      ),
      'getAdminSettings',
    );

    if (response is Map<String, dynamic>) {
      return AdminNotificationSettings.fromJson(response);
    }

    return null;
  }

  Future<bool> updateFarmerSettings(
      String userId,
      FarmerNotificationSettings settings,
      ) async {
    final res = await _safeCall(
          () => _apiClient.patch(
        '/notifications/notifications/farmer-settings/$userId',
        body: settings.toJson(),
      ),
      'updateFarmerSettings',
    );
    return res != null;
  }

  Future<bool> updateAdminSettings(
      String userId,
      AdminNotificationSettings settings,
      ) async {
    final res = await _safeCall(
          () => _apiClient.patch(
        '/notifications/notifications/admin-settings/$userId',
        body: settings.toJson(),
      ),
      'updateAdminSettings',
    );
    return res != null;
  }
}