// lib/features/admin/providers/message_provider.dart
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class AdminMessageProvider extends ChangeNotifier {
  final AdminMessageService _svc = AdminMessageService.instance;

  List<AdminMessageModel> _messages = [];
  bool _loading = false;
  String? _error;

  List<AdminMessageModel> get messages => _messages;
  bool get isLoading => _loading;
  String? get errorMsg => _error;

  // ── Fetch Messages ─────────────────────────────────────────────────────────

  Future<void> fetchMessages() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _svc.getAllMessages();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[AdminMessageProvider] fetchMessages error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
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
      final success = await _svc.replyToMessage(messageId: messageId, reply: reply);
      if (success) {
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
