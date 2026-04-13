import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/chatbot_models.dart';

class ChatbotService {
  ChatbotService._();
  static final ChatbotService instance = ChatbotService._();
  final ApiClient _c = ApiClient.instance;

  Future<ChatResponse> askBot({
    required String userId,
    required String question,
    required String language,
    String? sessionId,
  }) async {
    try {
      final normalizedLanguage = _normalizeLanguage(language);
      final response = await _c.postForm(
        '/chatbot/ask-farm-bot',
        {
          'user_id': userId,
          'question': question,
          'language': normalizedLanguage,
          if (sessionId != null) 'session_id': sessionId,
        },
      );
      return ChatResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChatHistoryItem>> getHistory(String userId, {String? sessionId}) async {
    try {
      final String path = '/chatbot/chat-history/$userId';
      final Map<String, String>? query = sessionId != null ? {'session_id': sessionId} : null;
      
      final data = await _c.get(path, query: query);
      final listData = _extractList(data, keys: const ['history', 'messages', 'data']);
      if (listData != null) {
        return listData
            .map((e) => ChatHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is List) {
        return data
            .map((e) => ChatHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw const ApiException('Failed to load chat history.');
    }
  }

  Future<List<ChatSession>> getUserSessions(String userId) async {
    try {
      final data = await _c.get('/chatbot/user-sessions/$userId');
      final listData = _extractList(data, keys: const ['sessions', 'chat_sessions', 'data']);
      if (listData != null) {
        return listData
            .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is List) {
        return data
            .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw const ApiException('Failed to load chat sessions.');
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    try {
      await _c.patchForm('/chatbot/rename-session/$sessionId', {'new_title': newTitle});
    } catch (e) {
      throw const ApiException('Failed to rename session.');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _c.delete('/chatbot/delete-session/$sessionId');
    } catch (e) {
      throw const ApiException('Failed to delete session.');
    }
  }

  String _normalizeLanguage(String language) {
    final value = language.trim().toLowerCase();
    if (value == 'arabic' || value == 'ar') return 'ar';
    if (value == 'english' || value == 'en') return 'en';
    return language;
  }

  List<dynamic>? _extractList(dynamic data, {required List<String> keys}) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final candidate = data[key];
        if (candidate is List) return candidate;
      }
    }
    return null;
  }
}
