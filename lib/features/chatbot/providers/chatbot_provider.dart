import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/chatbot_models.dart';
import '../services/chatbot_service.dart';

enum ChatStatus { idle, sending, error }

/// In-memory chat message for the UI conversation list.
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  }) : timestamp = DateTime.now();

  final String   text;
  final bool     isUser, isError;
  final DateTime timestamp;
}

class ChatbotProvider extends ChangeNotifier {
  ChatbotProvider(this.userId);

  final String          userId;
  final ChatbotService  _svc       = ChatbotService.instance;
  final List<ChatMessage> _messages = [];

  ChatStatus _status   = ChatStatus.idle;
  String?    _error;
  String     _language = 'English';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatStatus        get status   => _status;
  String?           get error    => _error;
  String            get language => _language;
  bool get isSending => _status == ChatStatus.sending;

  static const _supportedLanguages = ['English', 'Arabic'];
  List<String> get supportedLanguages => _supportedLanguages;

  void setLanguage(String lang) { _language = lang; notifyListeners(); }

  Future<void> send(String question) async {
    if (question.trim().isEmpty) return;

    _messages.add(ChatMessage(text: question.trim(), isUser: true));
    _status = ChatStatus.sending;
    _error  = null;
    notifyListeners();

    try {
      final resp = await _svc.ask(ChatRequest(
        userId:   userId,
        question: question.trim(),
        language: _language,
      ));
      _messages.add(ChatMessage(text: resp.response, isUser: false));
      _status = ChatStatus.idle;
    } on ApiException catch (e) {
      _error = e.message;
      _messages.add(ChatMessage(
          text: 'Error: ${e.message}', isUser: false, isError: true));
      _status = ChatStatus.error;
    } catch (_) {
      _error = 'Failed to get a response.';
      _messages.add(ChatMessage(
          text: _error!, isUser: false, isError: true));
      _status = ChatStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadHistory() async {
    if (_messages.isNotEmpty) return;
    try {
      final history = await _svc.getHistory(userId);
      for (final item in history) {
        _messages.add(ChatMessage(text: item.question, isUser: true));
        _messages.add(ChatMessage(text: item.response, isUser: false));
      }
      notifyListeners();
    } catch (_) { /* non-critical */ }
  }

  void clearChat() { _messages.clear(); _error = null; notifyListeners(); }
}
