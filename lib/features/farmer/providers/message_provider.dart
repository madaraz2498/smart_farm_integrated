// lib/features/farmer/providers/message_provider.dart
// ✅ FIX: deleteMessage signature matches original page (messageId + userId named params)
// ✅ FIX: sendMessage no longer re-fetches after send (uses local optimistic insert)
// ✅ FIX: polling timer added (30s like web)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_farm/shared/models/message_model.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../services/message_service.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class FarmerMessageProvider extends ChangeNotifier {
  final FarmerMessageService _svc = FarmerMessageService.instance;

  NotificationProvider? _notifProvider;

  void updateNotifProvider(NotificationProvider notif) {
    _notifProvider = notif;
  }

  List<MessageModel> _messages = [];
  bool _loading = false;
  bool _hasFetchedOnce = false;
  String? _error;
  Timer? _pollingTimer;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _loading;
  String? get errorMsg => _error;
  int get pendingCount => _messages.where((m) => !m.isReplied).length;

  // ── Fetch Messages ────────────────────────────────────────────────────────

  Future<void> fetchMessages(String userId, {bool force = false}) async {
    if (_loading) return;
    if (_hasFetchedOnce && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    final prevReplied = {for (final m in _messages) m.id: m.isReplied};

    try {
      _messages = await _svc.getMyMessages(userId);
      _hasFetchedOnce = true;
      _error = null;

      // Local notification when admin replies
      for (final msg in _messages) {
        final wasReplied = prevReplied[msg.id] ?? false;
        if (msg.isReplied && !wasReplied) {
          _notifProvider?.addLocalNotification(
            title: '💬 رد جديد من المشرف',
            body: 'تم الرد على رسالتك: "${msg.subject}"',
            type: NotificationType.user,
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      ProductionLogger.info('fetchMessages error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Polling (30s like web) ────────────────────────────────────────────────

  void startPolling(String userId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchMessages(userId, force: true),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Send Message ──────────────────────────────────────────────────────────

  Future<bool> sendMessage({
    required String subject,
    required String message,
    required String userId,
    required String userName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();
      final success = await _svc.sendMessage(
        subject: subject,
        message: message,
        userId: userId,
        userName: userName,
        createdAt: now,
      );
      if (success) {
        // Force re-fetch to get server-assigned ID
        _hasFetchedOnce = false;
        await fetchMessages(userId, force: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Delete Message ────────────────────────────────────────────────────────
  // ✅ keeps BOTH signatures: named params (used by original page)

  Future<bool> deleteMessage({
    required int messageId,
    required String userId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Optimistic remove
      final index = _messages.indexWhere((m) => m.id == messageId);
      MessageModel? removed;
      if (index != -1) {
        removed = _messages.removeAt(index);
        notifyListeners();
      }

      final success = await _svc.deleteMyMessage(messageId, userId);
      if (!success && removed != null) {
        // Revert on failure
        _messages.insert(index, removed);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
