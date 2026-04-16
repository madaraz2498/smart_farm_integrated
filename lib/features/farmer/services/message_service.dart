import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/message_model.dart';

class FarmerMessageService {
  FarmerMessageService._();
  static final FarmerMessageService instance = FarmerMessageService._();

  final ApiClient _c = ApiClient.instance;

  // ── Send Message ───────────────────────────────────────────────────────────
  Future<bool> sendMessage({
    required String subject,
    required String message,
    required String userId,
    required String userName,
    required String createdAt,
  }) async {
    try {
      final fields = {
        'subject': subject,
        'content': message,
        'user_id': userId,
        'user_name': userName,
        'created_at': createdAt,
      };
      await _c.postForm('/messages/send', fields);
      return true;
    } on ApiException catch (e) {
      debugPrint('[FarmerMessageService] sendMessage error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FarmerMessageService] sendMessage unknown error: $e');
      return false;
    }
  }

  // ── Get My Messages ────────────────────────────────────────────────────────
  Future<List<MessageModel>> getMyMessages(String userId) async {
    try {
      final List<dynamic> raw = await _c.get('/messages/my-messages/$userId');

      // 🔍 DEBUG: Print raw API response to see all field names
      if (raw.isNotEmpty) {
        debugPrint('[FarmerMessageService] Sample message keys: ${(raw.first as Map).keys.toList()}');
        debugPrint('[FarmerMessageService] Sample message data: ${raw.first}');
      }

      return raw.map((m) => MessageModel.fromJson(m)).toList();
    } on ApiException catch (e) {
      debugPrint('[FarmerMessageService] getMyMessages error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FarmerMessageService] getMyMessages unknown error: $e');
      return [];
    }
  }

  // ── Delete My Message ──────────────────────────────────────────────────────
  Future<bool> deleteMyMessage(int messageId, String userId) async {
    try {
      final query = {'user_id': userId};
      await _c.delete('/messages/delete/$messageId', query: query);
      return true;
    } on ApiException catch (e) {
      debugPrint('[FarmerMessageService] deleteMyMessage error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FarmerMessageService] deleteMyMessage unknown error: $e');
      return false;
    }
  }
}