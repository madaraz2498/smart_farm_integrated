// lib/features/admin/providers/message_provider.dart
// ✅ FIX: polling timer + optimistic delete

import 'dart:async';
import 'package:flutter/material.dart';
import 'admin_provider.dart';
import 'package:smart_farm/shared/models/message_model.dart';
import '../services/message_service.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class AdminMessageProvider extends ChangeNotifier {
  final AdminMessageService _svc = AdminMessageService.instance;
  AdminProvider? _adminProv;
  Timer? _pollingTimer;

  void updateAdminProv(AdminProvider? p) {
    _adminProv = p;
    if (_messages.isNotEmpty) {
      _enrichMessages();
      notifyListeners();
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

  // ✅ Polling 30s like web
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchMessages(force: true),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchMessages({bool force = false}) async {
    if (_loading) return;
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
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final needsName = msg.userName.isEmpty ||
          msg.userName == 'User' ||
          msg.userName == 'Unknown User';
      final needsEmail = msg.userEmail.isEmpty;
      if (needsName || needsEmail) {
        final name = needsName ? _adminProv!.getUserNameById(msg.userId) : null;
        final email =
            needsEmail ? _adminProv!.getUserEmailById(msg.userId) : null;
        if ((name != null && name.isNotEmpty && name != msg.userName) ||
            (email != null && email.isNotEmpty && email != msg.userEmail)) {
          _messages[i] = msg.copyWith(
            userName: (name != null && name.isNotEmpty) ? name : msg.userName,
            userEmail:
                (email != null && email.isNotEmpty) ? email : msg.userEmail,
          );
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

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
        _hasFetchedOnce = false;
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

  // ✅ Optimistic delete
  Future<bool> deleteMessage(int messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;
    final removed = _messages.removeAt(index);
    notifyListeners();
    try {
      final success = await _svc.deleteAnyMessage(messageId);
      if (!success) {
        _messages.insert(index, removed);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _messages.insert(index, removed);
      notifyListeners();
      return false;
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
