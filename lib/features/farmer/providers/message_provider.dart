// lib/features/farmer/messages/providers/message_provider.dart
import 'package:flutter/material.dart';
import 'package:smart_farm/shared/models/message_model.dart';
import '../services/message_service.dart';

class FarmerMessageProvider extends ChangeNotifier {
  final FarmerMessageService _svc = FarmerMessageService.instance;

  List<MessageModel> _messages = [];
  bool _loading = false;
  String? _error;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _loading;
  String? get errorMsg => _error;
  int get pendingCount => _messages.where((m) => !m.isReplied).length;

  // ── Fetch Messages ─────────────────────────────────────────────────────────

  Future<void> fetchMessages(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _svc.getMyMessages(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[FarmerMessageProvider] fetchMessages error: $e');
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
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();
      final success = await _svc.sendMessage(
        subject: subject,
        message: message,
        userId: userId, // Pass userId to the service
        userName: userName,
        createdAt: now,
      );
      if (success) {
        await fetchMessages(userId);
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
    required int messageId,
    required String userId,
  }) async {
    _loading = true;
    _error = null;
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
