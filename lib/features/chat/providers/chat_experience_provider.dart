import 'package:flutter/foundation.dart';
import '../models/chat_session_model.dart';
import '../repositories/chat_repository.dart';

// ── Load states ───────────────────────────────────────────────────────────────

enum SessionLoadState { idle, loading, loaded, error }

enum MessageLoadState { idle, loading, loaded, error }

enum SendState { idle, sending }

// ── Provider ──────────────────────────────────────────────────────────────────

/// Manages the full Chat Experience:
///  - Session list (sidebar)
///  - Active session / conversation
///  - Send message / receive response
///
/// Designed to be provided at the ChatScreen level so it is fully
/// independent of the main app navigation.
class ChatExperienceProvider extends ChangeNotifier {
  ChatExperienceProvider({
    required String userId,
    String language = 'English',
  })  : _userId = userId,
        _language = language;

  final ChatRepository _repo = ChatRepository.instance;

  // ── Identity ──────────────────────────────────────────────────────────────

  String _userId;
  String get userId => _userId;

  String _language;
  String get language => _language;

  static const List<String> supportedLanguages = ['English', 'Arabic'];

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  List<ChatSession> _sessions = [];
  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  SessionLoadState _sessionState = SessionLoadState.idle;
  SessionLoadState get sessionState => _sessionState;
  bool get isLoadingSessions => _sessionState == SessionLoadState.loading;

  String? _sessionError;
  String? get sessionError => _sessionError;

  ChatSession? _activeSession;
  ChatSession? get activeSession => _activeSession;

  Future<void> loadSessions() async {
    _sessionState = SessionLoadState.loading;
    _sessionError = null;
    notifyListeners();

    try {
      _sessions = await _repo.getUserSessions(_userId);
      _sessionState = SessionLoadState.loaded;

      // If no active session selected yet, try to keep the first one
      if (_activeSession == null && _sessions.isNotEmpty) {
        _activeSession = _sessions.first;
      }
    } catch (e) {
      _sessionState = SessionLoadState.error;
      _sessionError = e.toString();
      debugPrint('[ChatExperienceProvider] loadSessions error: $e');
    }
    notifyListeners();
  }

  void selectSession(ChatSession session) {
    if (_activeSession?.sessionId == session.sessionId) return;
    _activeSession = session;
    _messages.clear();
    _messageState = MessageLoadState.idle;
    _messageError = null;
    notifyListeners();
    loadHistory();
  }

  void newChat() {
    _activeSession = null;
    _messages.clear();
    _messageState = MessageLoadState.idle;
    _messageError = null;
    notifyListeners();
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final idx = _sessions.indexWhere((s) => s.sessionId == sessionId);
    if (idx == -1) return;

    // Optimistic update
    final original = _sessions[idx];
    _sessions[idx] = original.copyWith(title: newTitle);
    if (_activeSession?.sessionId == sessionId) {
      _activeSession = _sessions[idx];
    }
    notifyListeners();

    try {
      await _repo.renameSession(sessionId, newTitle);
    } catch (e) {
      // Rollback
      _sessions[idx] = original;
      if (_activeSession?.sessionId == sessionId) {
        _activeSession = original;
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final idx = _sessions.indexWhere((s) => s.sessionId == sessionId);
    if (idx == -1) return;

    // Optimistic removal
    final removed = _sessions.removeAt(idx);
    final wasActive = _activeSession?.sessionId == sessionId;
    if (wasActive) {
      _activeSession = _sessions.isNotEmpty ? _sessions.first : null;
      _messages.clear();
      _messageState = MessageLoadState.idle;
    }
    notifyListeners();

    try {
      await _repo.deleteSession(sessionId);
      // If active was deleted, load history for new active (if any)
      if (wasActive && _activeSession != null) {
        loadHistory();
      }
    } catch (e) {
      // Rollback
      _sessions.insert(idx, removed);
      if (wasActive) {
        _activeSession = removed;
      }
      notifyListeners();
      rethrow;
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  MessageLoadState _messageState = MessageLoadState.idle;
  MessageLoadState get messageState => _messageState;
  bool get isLoadingHistory => _messageState == MessageLoadState.loading;

  String? _messageError;
  String? get messageError => _messageError;

  Future<void> loadHistory() async {
    if (_messageState == MessageLoadState.loading) return;

    _messageState = MessageLoadState.loading;
    _messageError = null;
    notifyListeners();

    try {
      final history = await _repo.getChatHistory(_userId);
      _messages.clear();
      for (final item in history) {
        _messages.add(ChatMessage(
          text: item.message,
          isUser: item.isUser,
          timestamp: _parseTime(item.time),
        ));
      }
      _messageState = MessageLoadState.loaded;
    } catch (e) {
      _messageState = MessageLoadState.error;
      _messageError = e.toString();
      debugPrint('[ChatExperienceProvider] loadHistory error: $e');
    }
    notifyListeners();
  }

  // ── Send message ──────────────────────────────────────────────────────────

  SendState _sendState = SendState.idle;
  SendState get sendState => _sendState;
  bool get isSending => _sendState == SendState.sending;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isSending) return;

    final userMsg = ChatMessage(text: text.trim(), isUser: true);
    _messages.add(userMsg);
    _sendState = SendState.sending;
    notifyListeners();

    try {
      final resp = await _repo.askBot(
        userId: _userId,
        question: text.trim(),
        language: _language,
      );
      _messages.add(ChatMessage(text: resp.response, isUser: false));
      _sendState = SendState.idle;

      // After first message, refresh sessions list (a new session may have been created)
      if (_activeSession == null) {
        await loadSessions();
      }
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
        isError: true,
      ));
      _sendState = SendState.idle;
    }
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime _parseTime(String? timeStr) {
    if (timeStr == null) return DateTime.now();
    try {
      if (timeStr.contains('T')) return DateTime.parse(timeStr);
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        final now = DateTime.now();
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  String get sessionTitle {
    if (_activeSession != null) return _activeSession!.title;
    return language == 'Arabic' ? 'محادثة جديدة' : 'New Chat';
  }
}
