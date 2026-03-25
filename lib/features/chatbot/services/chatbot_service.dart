import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/chatbot_models.dart';

/// POST /chatbot/ask-farm-bot  — form-encoded (FastAPI uses Form fields, NOT JSON body)
/// GET  /chatbot/chat-history/{user_id}
class ChatbotService {
  ChatbotService._();
  static final ChatbotService instance = ChatbotService._();
  final ApiClient _c = ApiClient.instance;

  Future<ChatResponse> askBot({
    required String userId,
    required String question,
    required String language,
  }) async {
    debugPrint(
        '[ChatbotService] POST /chatbot/ask-farm-bot  userId=$userId  lang=$language');
    try {
      final response = await _c.postForm(
        '/chatbot/ask-farm-bot',
        {
          'user_id': userId,
          'question': question,
          'language': language,
        },
      );
      return ChatResponse.fromJson(response);
    } catch (e) {
      debugPrint('[ChatbotService] Error: $e');
      rethrow;
    }
  }

  Future<List<ChatHistoryItem>> getHistory(String userId) async {
    debugPrint('[ChatbotService] GET /chatbot/chat-history/$userId');
    try {
      final data = await _c.get('/chatbot/chat-history/$userId');
      debugPrint('[ChatbotService] history response: $data');
      if (data is List) {
        return data
            .map((e) => ChatHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException('Failed to load chat history.');
    }
  }
}
