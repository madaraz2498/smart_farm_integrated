// lib/features/notifications/providers/notification_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  FarmerNotificationSettings _farmerSettings =
  const FarmerNotificationSettings();
  AdminNotificationSettings _adminSettings = const AdminNotificationSettings();

  bool _isLoading = false;
  bool _isSettingsLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<AppNotification> get notifications => _notifications;
  FarmerNotificationSettings get farmerSettings => _farmerSettings;
  AdminNotificationSettings get adminSettings => _adminSettings;
  bool get isLoading => _isLoading;
  bool get isSettingsLoading => _isSettingsLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Fetch notifications ───────────────────────────────────────────────────

  Future<void> fetchNotifications({
    required String userId,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final results = await _service.getNotifications(userId);
      _notifications = results
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mark single as read ───────────────────────────────────────────────────

  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    final ok = await _service.markAsRead(notifId);
    if (!ok) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      notifyListeners();
    }
  }

  // ── Mark all as read ──────────────────────────────────────────────────────

  Future<void> markAllAsRead({required String userId}) async {
    if (_notifications.isEmpty) return;
    final previous = List<AppNotification>.from(_notifications);
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    final ok = await _service.markAllAsRead(userId);
    if (!ok) {
      _notifications = previous;
      notifyListeners();
    }
  }

  // ── Delete single ─────────────────────────────────────────────────────────

  Future<void> deleteNotification(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    final removed = _notifications.removeAt(index);
    notifyListeners();

    final ok = await _service.deleteNotification(notifId);
    if (!ok) {
      _notifications.insert(index, removed);
      notifyListeners();
    }
  }

  // ── Delete all ────────────────────────────────────────────────────────────

  Future<void> deleteAllNotifications({required String userId}) async {
    if (_notifications.isEmpty) return;
    final previous = List<AppNotification>.from(_notifications);
    _notifications = [];
    notifyListeners();

    final ok = await _service.deleteAllNotifications(userId);
    if (!ok) {
      _notifications = previous;
      notifyListeners();
    }
  }

  // ── Farmer settings ───────────────────────────────────────────────────────

  Future<void> fetchFarmerSettings({required String userId}) async {
    _isSettingsLoading = true;
    notifyListeners();

    final result = await _service.getFarmerSettings(userId);
    if (result != null) _farmerSettings = result;

    _isSettingsLoading = false;
    notifyListeners();
  }

  Future<bool> updateFarmerSettings({
    required String userId,
    required FarmerNotificationSettings updatedSettings,
  }) async {
    final previous = _farmerSettings;
    _farmerSettings = updatedSettings;
    notifyListeners();

    final ok = await _service.updateFarmerSettings(userId, updatedSettings);
    if (!ok) {
      _farmerSettings = previous;
      notifyListeners();
    }
    return ok;
  }

  // ── Admin settings ────────────────────────────────────────────────────────

  Future<bool> updateAdminSettings({
    required String userId,
    required AdminNotificationSettings updatedSettings,
  }) async {
    final previous = _adminSettings;
    _adminSettings = updatedSettings;
    notifyListeners();

    final ok = await _service.updateAdminSettings(userId, updatedSettings);
    if (!ok) {
      _adminSettings = previous;
      notifyListeners();
    }
    return ok;
  }

  // ── Local / in-app notifications ──────────────────────────────────────────

  void addLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'local',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: type,
        isRead: false,
      ),
    );
    notifyListeners();
  }

  void addSystemNotification({required String title, required String body}) =>
      addLocalNotification(
          title: title, body: body, type: NotificationType.system);

  // ── Timer ─────────────────────────────────────────────────────────────────

  void startRefreshTimer(String userId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchNotifications(userId: userId, showLoading: false);
    });
  }

  void stopRefreshTimer() => _refreshTimer?.cancel();

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}