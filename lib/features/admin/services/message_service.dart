// lib/features/admin/services/message_service.dart
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'package:smart_farm/shared/models/message_model.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class AdminMessageService {
  AdminMessageService._();
  static final AdminMessageService instance = AdminMessageService._();

  final ApiClient _c = ApiClient.instance;

  // ── Admin: Get All Messages ────────────────────────────────────────────────
  // GET /messages/admin/all-messages
  Future<List<MessageModel>> getAllMessages() async {
    try {
      final List<dynamic> raw = await _c.get('/messages/admin/all-messages');
      return raw.map((m) => MessageModel.fromJson(m)).toList();
    } on ApiException catch (e) {
      ProductionLogger.info('getAllMessages error: ${e.message}');
      rethrow;
    } catch (e) {
      ProductionLogger.info('getAllMessages unknown error: $e');
      return [];
    }
  }

  // ── Admin: Reply To Message ────────────────────────────────────────────────
  // POST /messages/admin/reply
  Future<bool> replyToMessage({
    required int messageId,
    required String reply,
  }) async {
    try {
      final fields = {
        'message_id': messageId.toString(),
        'reply_content': reply,
      };
      await _c.postForm('/messages/admin/reply', fields);
      return true;
    } on ApiException catch (e) {
      ProductionLogger.info('replyToMessage error: ${e.message}');
      rethrow;
    } catch (e) {
      ProductionLogger.info('replyToMessage unknown error: $e');
      return false;
    }
  }

  // ── Admin: Delete Any Message ──────────────────────────────────────────────
  // DELETE /messages/admin/delete/{message_id}
  Future<bool> deleteAnyMessage(int messageId) async {
    try {
      await _c.delete('/messages/admin/delete/$messageId');
      return true;
    } on ApiException catch (e) {
      ProductionLogger.info('deleteAnyMessage error: ${e.message}');
      rethrow;
    } catch (e) {
      ProductionLogger.info('deleteAnyMessage unknown error: $e');
      return false;
    }
  }
}
