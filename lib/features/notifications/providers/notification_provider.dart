import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  bool _pushEnabled = true;
  bool _emailEnabled = false;

  NotificationProvider();

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(
      {required String userId, bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final results = await _service.getNotifications(userId);

    // Merge backend results with current local notifications (avoiding duplicates)
    final backendIds = results.map((e) => e.id).toSet();
    final localOnly = _notifications
        .where((n) => !backendIds.contains(n.id) && n.userId == 'local')
        .toList();

    _notifications = [...results, ...localOnly];
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (showLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void addLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) {
    final newNotif = AppNotification(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      type: type,
      isRead: false,
    );
    _notifications.insert(0, newNotif);
    notifyListeners();
  }

  void addSystemNotification({required String title, required String body}) {
    addLocalNotification(
        title: title, body: body, type: NotificationType.system);
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final original = _notifications[index];
      if (original.isRead) return;

      _notifications[index] = original.copyWith(isRead: true);
      notifyListeners();

      if (original.userId != 'local') {
        await _service.markAsRead(id);
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.isEmpty) return;
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    // In a real app, we'd sync with backend too
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final item = _notifications.removeAt(index);
      notifyListeners();

      if (item.userId != 'local') {
        await _service.deleteNotification(id);
      }
    }
  }

  Future<void> updateSettings({
    required String userId,
    bool? push,
    bool? email,
  }) async {
    // In a real app, call service to update settings on backend
    if (push != null) _pushEnabled = push;
    if (email != null) _emailEnabled = email;
    notifyListeners();
  }

  void startRefreshTimer(String userId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchNotifications(userId: userId, showLoading: false);
    });
  }

  void stopRefreshTimer() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
