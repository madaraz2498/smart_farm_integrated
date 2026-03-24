// POST /chatbot/ask-farm-bot — form-encoded (FastAPI Form fields)
//   Fields: user_id, question, language
// GET  /chatbot/chat-history/{user_id}

class ChatRequest {
  const ChatRequest({
    required this.userId,
    required this.question,
    this.language = 'English',
  });

  final String userId, question, language;

  /// form-encoded — used with ApiClient.postForm()
  Map<String, String> toForm() => {
        'user_id':  userId,
        'question': question,
        'language': language,
      };
}

class ChatResponse {
  const ChatResponse({required this.response, this.language = 'English'});

  factory ChatResponse.fromJson(Map<String, dynamic> j) => ChatResponse(
        response: j['response'] as String? ??
            j['answer']  as String? ??
            j['reply']   as String? ??
            j['message'] as String? ??
            'Sorry, I could not understand that.',
        language: j['language'] as String? ?? 'English',
      );

  final String response, language;
}

/// A single entry from GET /chatbot/chat-history/{user_id}
class ChatHistoryItem {
  const ChatHistoryItem({
    required this.question,
    required this.response,
    this.timestamp,
    this.language = 'English',
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> j) => ChatHistoryItem(
        question:  j['question'] as String? ?? '',
        response:  j['response'] as String? ?? j['answer'] as String? ?? '',
        timestamp: j['timestamp'] as String? ?? j['created_at'] as String?,
        language:  j['language'] as String? ?? 'English',
      );

  final String  question, response, language;
  final String? timestamp;
}
