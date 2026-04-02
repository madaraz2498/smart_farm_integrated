// lib/features/farmer/services/message_service.dart
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/message_model.dart';

class FarmerMessageService {
  FarmerMessageService._();
  static final FarmerMessageService instance = FarmerMessageService._();

  final ApiClient _c = ApiClient.instance;

  // ── Send Message ───────────────────────────────────────────────────────────
  // POST /messages/send
  Future<bool> sendMessage({
    required String subject,
    required String message,
  }) async {
    try {
      final fields = {
        'subject': subject,
        'message': message,
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
  // GET /messages/my-messages/{user_id}
  Future<List<FarmerMessageModel>> getMyMessages(String userId) async {
    try {
      final List<dynamic> raw = await _c.get('/messages/my-messages/$userId');
      return raw.map((m) => FarmerMessageModel.fromJson(m)).toList();
    } on ApiException catch (e) {
      debugPrint('[FarmerMessageService] getMyMessages error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FarmerMessageService] getMyMessages unknown error: $e');
      return [];
    }
  }

  // ── Delete My Message ──────────────────────────────────────────────────────
  // DELETE /messages/delete/{message_id}
  Future<bool> deleteMyMessage(int messageId) async {
    try {
      await _c.delete('/messages/delete/$messageId');
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


