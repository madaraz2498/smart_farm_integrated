import 'package:flutter/foundation.dart';
import '../services/chatbot_service.dart';

enum ChatStatus { idle, sending, error }

/// In-memory chat message for the UI conversation list.
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String   text;
  final bool     isUser, isError;
  final DateTime timestamp;
}

class ChatbotProvider extends ChangeNotifier {
  ChatbotProvider(this._userId);

  String _userId;
  String get userId => _userId;

  void updateUserId(String id) {
    if (_userId != id) {
      _userId = id;
      _messages.clear(); // Clear chat when user changes
      notifyListeners();
    }
  }

  final ChatbotService  _svc       = ChatbotService.instance;
  final List<ChatMessage> _messages = [];

  ChatStatus _status   = ChatStatus.idle;
  String?    _error;
  String     _chatLanguage = 'English';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatStatus        get status   => _status;
  String?           get error    => _error;
  String            get chatLanguage => _chatLanguage;
  bool get isSending => _status == ChatStatus.sending;

  static const _supportedLanguages = ['English', 'Arabic'];
  List<String> get supportedLanguages => _supportedLanguages;

  void setLanguage(String lang) { _chatLanguage = lang; notifyListeners(); }

  Future<void> send(String text) async {
    if (text.isEmpty || isSending) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    _messages.add(userMsg);
    _status = ChatStatus.sending;
    _error = null;
    notifyListeners();

    try {
      final response = await _svc.askBot(
        userId:   userId,
        question: text,
        language: _chatLanguage,
      );
      _messages.add(ChatMessage(text: response.response, isUser: false));
      _status = ChatStatus.idle;
    } catch (e) {
      _status = ChatStatus.error;
      _messages.add(ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
        isError: true,
      ));
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    if (_messages.isNotEmpty) return;
    try {
      final history = await _svc.getHistory(userId);
      for (final item in history) {
        _messages.add(ChatMessage(
          text: item.message,
          isUser: item.isUser,
          timestamp: _parseTime(item.time),
        ));
      }
      notifyListeners();
    } catch (_) { /* non-critical */ }
  }

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) { return null; }
  }

  void clearChat() { _messages.clear(); _error = null; notifyListeners(); }
}
