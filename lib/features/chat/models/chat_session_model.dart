/// Models for the full Chat Experience feature.
///
/// API contracts:
///   GET  /chatbot/user-sessions/{user_id}          → List<ChatSession>
///   PATCH /chatbot/rename-session/{session_id}     → body: {title}
///   DELETE /chatbot/delete-session/{session_id}
///   GET  /chatbot/chat-history/{user_id}           → List<ChatHistoryItem>
///   POST /chatbot/ask-farm-bot                     → form-encoded

// ── Chat Session ─────────────────────────────────────────────────────────────

class ChatSession {
  const ChatSession({
    required this.sessionId,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  final String sessionId;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChatSession.fromJson(Map<String, dynamic> j) {
    return ChatSession(
      sessionId: (j['session_id'] ?? j['id'] ?? '').toString(),
      title: (j['title'] ?? j['name'] ?? 'Chat Session').toString(),
      createdAt: _parseDate(j['created_at']),
      updatedAt: _parseDate(j['updated_at']),
    );
  }

  ChatSession copyWith({String? title}) {
    return ChatSession(
      sessionId: sessionId,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }
}

// ── Chat Message (UI model) ───────────────────────────────────────────────────

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final bool isError;
  final DateTime timestamp;
}

// ── Chat History Item (API model) ─────────────────────────────────────────────

class ChatHistoryItem {
  const ChatHistoryItem({
    required this.message,
    required this.isUser,
    this.time,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> j) => ChatHistoryItem(
        message: (j['message'] ?? j['text'] ?? '').toString(),
        isUser: (j['sender'] ?? '').toString().toLowerCase() == 'user',
        time: j['time']?.toString(),
      );

  final String message;
  final bool isUser;
  final String? time;
}

// ── Ask Bot Request/Response ──────────────────────────────────────────────────

class AskBotResponse {
  const AskBotResponse({required this.response, this.language = 'English'});

  factory AskBotResponse.fromJson(Map<String, dynamic> j) => AskBotResponse(
        response: (j['bot_response'] ??
                j['response'] ??
                j['answer'] ??
                j['reply'] ??
                j['message'] ??
                'Sorry, I could not understand that.')
            .toString(),
        language: (j['language'] ?? 'English').toString(),
      );

  final String response;
  final String language;
}
