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

  bool _isLocalId(String id) => id.startsWith('local_');
  bool _isBackendIntId(String id) => int.tryParse(id) != null;
  bool _shouldCallBackend(String notifId) =>
      _isBackendIntId(notifId) && !_isLocalId(notifId);

  String _normalizeText(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return '';
    // Remove most emoji/symbol chars + collapse spaces.
    final noEmoji = trimmed.replaceAll(RegExp(r'[^\x00-\x7Fء-ي0-9A-Za-z\s]'), '');
    return noEmoji.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  String _signature(AppNotification n) =>
      '${n.type.name}::${_normalizeText(n.title)}::${_normalizeText(n.body)}';

  bool _existsSimilar({
    required String title,
    required String body,
    required NotificationType type,
    required Duration within,
  }) {
    final sig = '${type.name}::${_normalizeText(title)}::${_normalizeText(body)}';
    final now = DateTime.now();
    for (final n in _notifications) {
      if (_signature(n) != sig) continue;
      final diff = now.difference(n.createdAt);
      if (!diff.isNegative && diff <= within) return true;
    }
    return false;
  }

  // ── Fetch notifications ───────────────────────────────────────────────────

  Future<void> fetchNotifications(String userId, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final server = await _service.getNotifications(userId)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final serverSignatures = server.map(_signature).toSet();

      // Keep local-only items for instant UX, but let server data replace
      // any matching IDs (dedupe is by id).
      // If the same notification arrived from server (different id),
      // drop the local duplicate.
      final local = _notifications
          .where((n) => n.id.startsWith('local_'))
          .where((n) => !serverSignatures.contains(_signature(n)))
          .toList();

      final merged = _mergeUniqueById([
        ...local,
        ...server,
      ]);

      _notifications = merged.take(50).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<AppNotification> _mergeUniqueById(List<AppNotification> items) {
    final seen = <String>{};
    final out = <AppNotification>[];
    for (final n in items) {
      final id = n.id.trim();
      if (id.isEmpty) continue;
      if (seen.add(id)) out.add(n);
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  // ── Mark single as read ───────────────────────────────────────────────────

  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    // Backend expects integer notif_id. Non-int (or local_) is UI-only.
    if (!_shouldCallBackend(notifId)) return;

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

    // Backend expects integer notif_id. Non-int (or local_) is UI-only.
    if (!_shouldCallBackend(notifId)) return;

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

    // Optimistic: clear all locally (including local-only items).
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

  void addNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) {
    // Prevent local duplicates (e.g. action triggers twice quickly).
    if (_existsSimilar(
      title: title,
      body: body,
      type: type,
      within: const Duration(minutes: 2),
    )) {
      return;
    }

    final notification = AppNotification(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      type: type,
      isRead: false,
    );

    _notifications = _mergeUniqueById([notification, ..._notifications]).take(50).toList();
    notifyListeners();
  }

  // Backwards-compatible alias (older call sites in farmer/admin providers).
  void addLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) =>
      addNotification(title: title, body: body, type: type);

  void addSystemNotification({required String title, required String body}) =>
      addLocalNotification(
          title: title, body: body, type: NotificationType.system);

  // ── Timer ─────────────────────────────────────────────────────────────────

  void startRefreshTimer(String userId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchNotifications(userId, showLoading: false);
    });
  }

  void stopRefreshTimer() => _refreshTimer?.cancel();

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}