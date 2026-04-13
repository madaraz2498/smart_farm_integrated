import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/chat_session_model.dart';

/// Repository layer — isolates all chatbot API calls.
///
/// Endpoints:
///   GET    /chatbot/user-sessions/{user_id}
///   PATCH  /chatbot/rename-session/{session_id}   body: {"title": "..."}
///   DELETE /chatbot/delete-session/{session_id}
///   GET    /chatbot/chat-history/{user_id}
///   POST   /chatbot/ask-farm-bot                  form: {user_id, question, language}
class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final ApiClient _api = ApiClient.instance;

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<List<ChatSession>> getUserSessions(String userId) async {
    debugPrint('[ChatRepository] GET /chatbot/user-sessions/$userId');
    try {
      final data = await _api.get('/chatbot/user-sessions/$userId');
      if (data is List) {
        return data
            .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load sessions: $e');
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    debugPrint('[ChatRepository] PATCH /chatbot/rename-session/$sessionId');
    try {
      await _api.patch(
        '/chatbot/rename-session/$sessionId',
        body: {'title': newTitle},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to rename session: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    debugPrint('[ChatRepository] DELETE /chatbot/delete-session/$sessionId');
    try {
      await _api.delete('/chatbot/delete-session/$sessionId');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete session: $e');
    }
  }

  // ── Chat History ──────────────────────────────────────────────────────────

  Future<List<ChatHistoryItem>> getChatHistory(String userId) async {
    debugPrint('[ChatRepository] GET /chatbot/chat-history/$userId');
    try {
      final data = await _api.get('/chatbot/chat-history/$userId');
      if (data is List) {
        return data
            .map((e) => ChatHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load chat history: $e');
    }
  }

  // ── Ask Bot ───────────────────────────────────────────────────────────────

  Future<AskBotResponse> askBot({
    required String userId,
    required String question,
    required String language,
  }) async {
    debugPrint('[ChatRepository] POST /chatbot/ask-farm-bot userId=$userId');
    try {
      final response = await _api.postForm(
        '/chatbot/ask-farm-bot',
        {
          'user_id': userId,
          'question': question,
          'language': language,
        },
      );
      return AskBotResponse.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to send message: $e');
    }
  }
}
