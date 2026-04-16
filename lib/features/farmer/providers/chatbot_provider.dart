import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../services/chatbot_service.dart';
import '../models/chatbot_models.dart';

enum ChatStatus { idle, loading, sending, error }

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser, isError;
  final DateTime timestamp;
}

class ChatbotProvider extends ChangeNotifier {
  ChatbotProvider(this._userId);

  String _userId;
  String get userId => _userId;

  NotificationProvider? _notifProvider;

  void updateUserId(String id) {
    if (_userId != id) {
      _userId = id;
      _messages.clear();
      _sessions.clear();
      _currentSessionId = null;
      notifyListeners();
    }
  }

  void updateNotifProvider(NotificationProvider notif) {
    _notifProvider = notif;
  }

  final ChatbotService _svc = ChatbotService.instance;
  final List<ChatMessage> _messages = [];
  final List<ChatSession> _sessions = [];
  String? _currentSessionId;

  ChatStatus _status = ChatStatus.idle;
  String? _error;
  String _chatLanguage = 'English';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get currentSessionId => _currentSessionId;
  ChatStatus get status => _status;
  String? get error => _error;
  String get chatLanguage => _chatLanguage;
  bool get isSending => _status == ChatStatus.sending;
  bool get isLoading => _status == ChatStatus.loading;

  static const _supportedLanguages = ['English', 'Arabic'];
  List<String> get supportedLanguages => _supportedLanguages;

  void setLanguage(String lang) {
    _chatLanguage = lang;
    notifyListeners();
  }

  Future<void> send(String text) async {
    if (text.isEmpty || isSending) return;

    final previousSessionId = _currentSessionId;
    final userMsg = ChatMessage(text: text, isUser: true);
    _messages.add(userMsg);
    _status = ChatStatus.sending;
    _error = null;
    notifyListeners();

    try {
      final requestLanguage = _resolveRequestLanguage(text);
      final response = await _svc.askBot(
        userId: userId,
        question: text,
        language: requestLanguage,
        sessionId: _currentSessionId,
      );
      
      _messages.add(ChatMessage(text: response.response, isUser: false));
      
      // Avoid extra API roundtrip for faster UX after first message.
      if (previousSessionId == null && response.sessionId != null) {
        _currentSessionId = response.sessionId;
        _upsertSession(
          ChatSession(
            id: response.sessionId!,
            title: _titleFromMessage(text),
            createdAt: DateTime.now(),
          ),
        );
      }
      
      _status = ChatStatus.idle;

      _notifProvider?.addNotification(
        title: '🤖 رد الذكاء الاصطناعي جاهز',
        body: response.response.length > 80
            ? '${response.response.substring(0, 80)}...'
            : response.response,
        type: NotificationType.chatbot,
      );

      if (userId.isNotEmpty && userId != '0') {
        unawaited(_notifProvider?.fetchNotifications(userId) ?? Future.value());
      }
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

  Future<void> loadSessions() async {
    _status = ChatStatus.loading;
    notifyListeners();
    try {
      final fetchedSessions = await _svc.getUserSessions(userId);
      _sessions.clear();
      _sessions.addAll(fetchedSessions);
      _status = ChatStatus.idle;
    } catch (e) {
      _status = ChatStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> selectSession(String? sessionId) async {
    _currentSessionId = sessionId;
    _messages.clear();
    _error = null;
    if (sessionId != null) {
      await loadHistory();
    } else {
      _status = ChatStatus.idle;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _status = ChatStatus.loading;
    notifyListeners();
    try {
      final history = await _svc.getHistory(userId, sessionId: _currentSessionId);
      _messages.clear();
      for (final item in history) {
        _messages.add(ChatMessage(
          text: item.message,
          isUser: item.isUser,
          timestamp: _parseTime(item.time),
        ));
      }
      _status = ChatStatus.idle;
    } catch (e) {
      _status = ChatStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final oldSession = _sessions[index];
    final trimmedTitle = newTitle.trim();
    if (trimmedTitle.isEmpty || trimmedTitle == oldSession.title) return;

    // Optimistic update for instant UI feedback.
    _sessions[index] = ChatSession(
      id: oldSession.id,
      title: trimmedTitle,
      createdAt: oldSession.createdAt,
    );
    notifyListeners();

    try {
      await _svc.renameSession(sessionId, trimmedTitle);
    } catch (e) {
      _sessions[index] = oldSession;
      notifyListeners();
      debugPrint('Rename failed: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _svc.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages.clear();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  void clearChat() {
    _currentSessionId = null;
    _messages.clear();
    _error = null;
    _status = ChatStatus.idle;
    notifyListeners();
  }

  void _upsertSession(ChatSession session) {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index == -1) {
      _sessions.insert(0, session);
      return;
    }
    _sessions[index] = session;
  }

  String _titleFromMessage(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) return 'New Chat';
    if (normalized.length <= 28) return normalized;
    return '${normalized.substring(0, 28)}...';
  }

  String _resolveRequestLanguage(String text) {
    // Auto-detect Arabic/English from message characters, then fallback to UI selection.
    if (_containsArabic(text)) return 'Arabic';
    if (_containsEnglish(text)) return 'English';
    return _chatLanguage;
  }

  bool _containsArabic(String text) =>
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);

  bool _containsEnglish(String text) => RegExp(r'[A-Za-z]').hasMatch(text);
}
