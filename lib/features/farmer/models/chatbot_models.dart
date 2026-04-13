class ChatRequest {
  const ChatRequest({
    required this.userId,
    required this.question,
    this.language = 'English',
    this.sessionId,
  });

  final String userId, question, language;
  final String? sessionId;

  Map<String, String> toForm() {
    final map = {
      'user_id': userId,
      'question': question,
      'language': language,
    };
    if (sessionId != null) map['session_id'] = sessionId!;
    return map;
  }
}

class ChatResponse {
  const ChatResponse({
    required this.response,
    this.language = 'English',
    this.sessionId,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> j) => ChatResponse(
        response: j['bot_response'] as String? ??
            j['response'] as String? ??
            j['answer'] as String? ??
            j['reply'] as String? ??
            j['message'] as String? ??
            'Sorry, I could not understand that.',
        language: j['language'] as String? ?? 'English',
        sessionId: j['session_id']?.toString(),
      );

  final String response, language;
  final String? sessionId;
}

class ChatHistoryItem {
  const ChatHistoryItem({
    required this.message,
    required this.isUser,
    this.time,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> j) => ChatHistoryItem(
        message: j['message'] as String? ?? j['text'] as String? ?? '',
        isUser: (j['sender'] as String? ?? '').toLowerCase() == 'user' ||
            (j['is_user'] as bool? ?? false),
        time: j['time'] as String?,
      );

  final String message;
  final bool isUser;
  final String? time;
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: j['id']?.toString() ?? j['session_id']?.toString() ?? '',
        title: j['title'] as String? ?? 'New Chat',
        createdAt: DateTime.parse(j['created_at'] as String? ?? DateTime.now().toIso8601String()),
      );

  final String id;
  final String title;
  final DateTime createdAt;
}
