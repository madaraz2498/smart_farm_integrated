// lib/features/farmer/providers/message_provider.dart
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class FarmerMessageProvider extends ChangeNotifier {
  final FarmerMessageService _svc = FarmerMessageService.instance;

  List<FarmerMessageModel> _messages = [];
  bool _loading = false;
  String? _error;

  List<FarmerMessageModel> get messages => _messages;
  bool get isLoading => _loading;
  String? get errorMsg => _error;

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
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _svc.sendMessage(subject: subject, message: message);
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

  // ── Delete Message ─────────────────────────────────────────────────────────

  Future<bool> deleteMessage({
    required int messageId,
    required String userId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _svc.deleteMyMessage(messageId);
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
