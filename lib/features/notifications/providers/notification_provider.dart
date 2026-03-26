import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  static const String _storageKey = 'system_activity_logs';

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  bool _pushEnabled = true;
  bool _emailEnabled = false;

  NotificationProvider() {
    _loadFromStorage();
  }

  // ── Storage ────────────────────────────────────────────────────────────────
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final localLogs = decoded
            .map((item) =>
                AppNotification.fromJson(item as Map<String, dynamic>))
            .toList();

        _notifications = [...localLogs];
        debugPrint(
            '[NotificationProvider] Loaded ${_notifications.length} notifications from storage.');
      } else {
        debugPrint(
            '[NotificationProvider] No saved logs found. Creating dummy data.');
        // Initial dummy data for the first run since backend is missing
        _notifications = [
          AppNotification(
            id: 'init_1',
            userId: 'local',
            title: 'System Ready',
            body: 'Smart Farm AI system is online and ready.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            type: NotificationType.system,
            isRead: false,
          ),
          AppNotification(
            id: 'init_2',
            userId: 'local',
            title: 'Welcome Admin',
            body: 'You have full access to the system management dashboard.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
            type: NotificationType.system,
            isRead: false,
          ),
        ];
        _saveToStorage();
      }
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading logs: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep only last 50 activities to avoid bloating storage
      final toSave = _notifications.take(50).map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(toSave));
      debugPrint(
          '[NotificationProvider] Saved ${toSave.length} notifications to storage.');
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving logs: $e');
    }
  }

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchNotifications(
      {required String userId, bool showLoading = true}) async {
    // Disabled remote fetching because backend endpoint is missing (404)
    // We rely purely on local storage for now.
    /*
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await _service.getNotifications(userId);
      final localOnly = _notifications
          .where((n) => n.userId == 'local' && !n.isRead)
          .toList();

      _notifications = [...results, ...localOnly];
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('[NotificationProvider] fetch error: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
    */
  }

  void addLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) {
    debugPrint(
        '[NotificationProvider] Adding local notification: $title - $body');
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
    _saveToStorage();
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
      _saveToStorage();

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
    _saveToStorage();
    // In a real app, we'd sync with backend too
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final item = _notifications.removeAt(index);
      notifyListeners();
      _saveToStorage();

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
