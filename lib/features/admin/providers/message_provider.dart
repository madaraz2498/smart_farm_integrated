// lib/features/admin/providers/message_provider.dart
import 'package:flutter/material.dart';
import 'admin_provider.dart';
import 'package:smart_farm/shared/models/message_model.dart';
import '../services/message_service.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class AdminMessageProvider extends ChangeNotifier {
  final AdminMessageService _svc = AdminMessageService.instance;
  AdminProvider? _adminProv;

  void updateAdminProv(AdminProvider? p) {
    _adminProv = p;
    if (_messages.isNotEmpty) {
      _enrichMessages();
    }
  }

  List<MessageModel> _messages = [];
  bool _loading = false;
  bool _hasFetchedOnce = false;
  String? _error;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _loading;
  String? get errorMsg => _error;
  int get pendingCount => _messages.where((m) => !m.isReplied).length;

  // ── Fetch Messages ─────────────────────────────────────────────────────────

  Future<void> fetchMessages({bool force = false}) async {
    // Skip if already in-flight (prevents concurrent duplicate API calls).
    if (_loading) return;
    // Skip if already loaded and caller is not explicitly forcing a refresh.
    if (_hasFetchedOnce && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _svc.getAllMessages();
      _messages = list;
      _hasFetchedOnce = true;
      _enrichMessages();
      _error = null;
    } catch (e) {
      _error = e.toString();
      ProductionLogger.info('fetchMessages error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _enrichMessages() {
    if (_adminProv == null) return;
    bool changed = false;

    // Debug users length
    ProductionLogger.info('Enriching _${_messages.length} messages. AdminProvider has _${_adminProv!.users.length} users.');

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      // Check for 'Unknown User' specifically as shown in screenshot
      if (msg.userName.isEmpty ||
          msg.userName == 'User' ||
          msg.userName == 'Unknown User' ||
          msg.userName == 'مستخدم مجهول') {
        final name = _adminProv!.getUserNameById(msg.userId);
        ProductionLogger.info('Message ${msg.id} has userId ${msg.userId}. Found name: "$name"');

        if (name.isNotEmpty && name != msg.userName) {
          _messages[i] = msg.copyWith(userName: name);
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  // ── Admin: Reply ───────────────────────────────────────────────────────────

  Future<bool> replyToMessage({
    required int messageId,
    required String reply,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success =
          await _svc.replyToMessage(messageId: messageId, reply: reply);
      if (success) {
        _hasFetchedOnce = false; // invalidate cache so reload fetches fresh data
        await fetchMessages();
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

  // ── Admin: Delete Message ──────────────────────────────────────────────────

  Future<bool> deleteMessage(int messageId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _svc.deleteAnyMessage(messageId);
      if (success) {
        _hasFetchedOnce = false; // invalidate cache so reload fetches fresh data
        await fetchMessages();
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
