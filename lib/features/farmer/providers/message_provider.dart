// lib/features/farmer/messages/providers/message_provider.dart
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
  bool               _loading  = false;
  bool               _hasFetchedOnce = false;
  String?            _error;

  List<MessageModel> get messages     => _messages;
  bool               get isLoading    => _loading;
  String?            get errorMsg     => _error;
  int                get pendingCount => _messages.where((m) => !m.isReplied).length;

  // ── Fetch Messages ─────────────────────────────────────────────────────────

  Future<void> fetchMessages(String userId, {bool force = false}) async {
    // Prevent concurrent duplicate network calls.
    if (_loading) return;
    // Use cached data if already loaded and not forcing a refresh.
    if (_hasFetchedOnce && !force) return;

    _loading = true;
    _error   = null;
    notifyListeners();

    final prevReplied = {for (final m in _messages) m.id: m.isReplied};

    try {
      _messages = await _svc.getMyMessages(userId);
      _hasFetchedOnce = true;
      _error    = null;

      // Notify farmer when admin replies to a message
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

  // ── Send Message ───────────────────────────────────────────────────────────

  Future<bool> sendMessage({
    required String subject,
    required String message,
    required String userId,
    required String userName,
  }) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final now     = DateTime.now().toIso8601String();
      final success = await _svc.sendMessage(
        subject:   subject,
        message:   message,
        userId:    userId,
        userName:  userName,
        createdAt: now,
      );
      if (success) {
        await fetchMessages(userId);
        _notifProvider?.addLocalNotification(
          title: '✉️ تم إرسال رسالتك',
          body: 'تم إرسال رسالتك "$subject" بنجاح وستصلك إجابة قريباً',
          type: NotificationType.user,
        );
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

  // ── Delete Message ─────────────────────────────────────────────────────────

  Future<bool> deleteMessage({
    required int    messageId,
    required String userId,
  }) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final success = await _svc.deleteMyMessage(messageId, userId);
      if (success) {
        await fetchMessages(userId);
        return true;
      }
      return false;
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
}