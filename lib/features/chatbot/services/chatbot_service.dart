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

  Future<ChatResponse> ask(ChatRequest req) async {
    debugPrint('[ChatbotService] POST /chatbot/ask-farm-bot  userId=${req.userId}');
    debugPrint('[ChatbotService] form: ${req.toForm()}');
    try {
      final data = await _c.postForm('/chatbot/ask-farm-bot', req.toForm());
      debugPrint('[ChatbotService] response: $data');
      return ChatResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (e) { throw const ApiException('Failed to get a chatbot response.'); }
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
    } on ApiException { rethrow; }
    catch (e) { throw const ApiException('Failed to load chat history.'); }
  }
}
