// lib/features/notifications/providers/notification_provider.dart

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

  NotificationProvider() {
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchNotifications(showLoading: false);
    });
  }

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;

  Future<void> fetchNotifications({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    
    final results = await _service.getNotifications();
    _notifications = results;
    
    if (showLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    // Update local state immediately for responsiveness
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final original = _notifications[index];
      _notifications[index] = original.copyWith(isRead: true);
      notifyListeners();

      // Attempt to sync with server
      final success = await _service.markAsRead(id);
      if (!success) {
        // Rollback if needed, but for now we trust local state
        debugPrint('[NotificationProvider] Failed to sync markAsRead for $id');
      }
    }
  }

  Future<void> markAllAsRead() async {
    // Update local state immediately
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    // Sync with server
    final success = await _service.markAllAsRead();
    if (!success) {
      debugPrint('[NotificationProvider] Failed to sync markAllAsRead');
    }
  }

  Future<void> deleteNotification(String id) async {
    // Update local state immediately
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final removedItem = _notifications.removeAt(index);
      notifyListeners();

      // Sync with server
      final success = await _service.deleteNotification(id);
      if (!success) {
        debugPrint(
            '[NotificationProvider] Failed to sync deleteNotification for $id');
        // Option: add it back if it's critical, but usually users prefer immediate UI
      }
    }
  }

  Future<void> updateSettings({
    required String userId,
    bool? push,
    bool? email,
  }) async {
    final success = await _service.updateNotificationSettings(
      userId: userId,
      push: push,
      email: email,
    );
    if (success) {
      if (push != null) _pushEnabled = push;
      if (email != null) _emailEnabled = email;
      notifyListeners();
    }
  }

  void addSystemNotification({required String title, required String message}) {
    final newNotif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: NotificationType.system,
      isRead: false,
    );
    _notifications.insert(0, newNotif);
    notifyListeners();
  }
}
