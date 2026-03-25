// lib/features/notifications/services/notification_service.dart

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _apiClient.get('/admin/notifications/list');
      if (response is List) {
        return response.map((json) => AppNotification.fromJson(json)).toList();
      }
      return _getMockNotifications();
    } catch (e) {
      debugPrint('[NotificationService] Error: $e');
      return _getMockNotifications();
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _apiClient.post('/admin/notifications/mark-read/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _apiClient.post('/admin/notifications/mark-all-read');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await _apiClient.delete('/admin/notifications/delete/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotificationSettings({
    required String userId,
    bool? push,
    bool? email,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (push != null) queryParams['push'] = push.toString();
      if (email != null) queryParams['email'] = email.toString();

      await _apiClient.get(
        '/admin/users/settings/notifications/$userId',
        query: queryParams,
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Update Settings Error: $e');
      return false;
    }
  }

  List<AppNotification> _getMockNotifications() {
    return [
      AppNotification(
        id: '1',
        title: 'تحليل جديد للنبات',
        message: 'تم إجراء تحليل لمرض "لفحة الأوراق" بنجاح للمستخدم أحمد.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NotificationType.analysis,
        isRead: false,
      ),
      AppNotification(
        id: '2',
        title: 'تسجيل مستخدم جديد',
        message: 'انضم مزارع جديد "خالد محمد" إلى المنصة الآن.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.user,
        isRead: false,
      ),
      AppNotification(
        id: '3',
        title: 'تنبيه النظام',
        message: 'تم تحديث نماذج الذكاء الاصطناعي إلى الإصدار v2.1.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.system,
        isRead: true,
      ),
      AppNotification(
        id: '4',
        title: 'تقرير تم إنشاؤه',
        message: 'التقرير السنوي للمزرعة جاهز للتحميل الآن.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.analysis,
        isRead: true,
      ),
    ];
  }
}
