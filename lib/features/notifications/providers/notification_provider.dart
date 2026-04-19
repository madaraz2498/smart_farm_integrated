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

  // ── Fetch guard: prevents concurrent AND rapid-sequential duplicate calls ──
  bool _isFetching = false;
  DateTime? _lastFetchTime;
  // Minimum gap between two fetches (ignores calls that arrive too soon)
  static const _kMinFetchInterval = Duration(seconds: 3);

  Future<void> fetchNotifications({
    required String userId,
    bool showLoading = true,
  }) async {
    // Block if already in-flight
    if (_isFetching) return;

    // Block if last fetch finished less than 3 seconds ago (debounce)
    final now = DateTime.now();
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _kMinFetchInterval) {
      return;
    }

    _isFetching = true;

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
      _lastFetchTime = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Backward-compatible alias — allows calling with a positional userId arg:
  ///   provider.fetchNotificationsForUser(userId)
  Future<void> fetchNotificationsForUser(String userId) =>
      fetchNotifications(userId: userId, showLoading: false);

  // ── startRefreshTimer also accepts the provider used via positional string ─

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
        id: 'local_\${DateTime.now().millisecondsSinceEpoch}',
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

  /// Backward-compatible alias — allows: provider.addNotification(title: '...', body: '...', type: ...)
  void addNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
  }) =>
      addLocalNotification(title: title, body: body, type: type);

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