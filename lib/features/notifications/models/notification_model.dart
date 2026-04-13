// lib/features/notifications/models/notification_model.dart

enum NotificationType { system, report, user, chatbot }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type.name,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      type: _parseType(json['type']),
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'report':
        return NotificationType.report;
      case 'user':
        return NotificationType.user;
      case 'chatbot':
        return NotificationType.chatbot;
      default:
        return NotificationType.system;
    }
  }
}

/// Farmer notification settings — matches API response exactly:
/// { "email_notifications_farmer": bool,
///   "analysis_completion_alerts": bool,
///   "weekly_report_summary": bool }
class FarmerNotificationSettings {
  final bool emailNotificationsFarmer;
  final bool analysisCompletionAlerts;
  final bool weeklyReportSummary;

  const FarmerNotificationSettings({
    this.emailNotificationsFarmer = false,
    this.analysisCompletionAlerts = true,
    this.weeklyReportSummary = false,
  });

  factory FarmerNotificationSettings.fromJson(Map<String, dynamic> json) {
    // API wraps fields under a "settings" key
    final data = json['settings'] is Map
        ? json['settings'] as Map<String, dynamic>
        : json;
    return FarmerNotificationSettings(
      emailNotificationsFarmer:
      data['email_notifications_farmer'] ?? false,
      analysisCompletionAlerts:
      data['analysis_completion_alerts'] ?? true,
      weeklyReportSummary: data['weekly_report_summary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'email_notifications_farmer': emailNotificationsFarmer,
    'analysis_completion_alerts': analysisCompletionAlerts,
    'weekly_report_summary': weeklyReportSummary,
  };

  FarmerNotificationSettings copyWith({
    bool? emailNotificationsFarmer,
    bool? analysisCompletionAlerts,
    bool? weeklyReportSummary,
  }) =>
      FarmerNotificationSettings(
        emailNotificationsFarmer:
        emailNotificationsFarmer ?? this.emailNotificationsFarmer,
        analysisCompletionAlerts:
        analysisCompletionAlerts ?? this.analysisCompletionAlerts,
        weeklyReportSummary: weeklyReportSummary ?? this.weeklyReportSummary,
      );
}

/// Admin notification settings (kept separate from farmer settings)
class AdminNotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;

  const AdminNotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
  });

  factory AdminNotificationSettings.fromJson(Map<String, dynamic> json) {
    final data = json['settings'] is Map
        ? json['settings'] as Map<String, dynamic>
        : json;
    return AdminNotificationSettings(
      pushNotifications: data['push_notifications'] ?? data['push'] ?? true,
      emailNotifications:
      data['email_notifications'] ?? data['email'] ?? true,
      smsNotifications: data['sms_notifications'] ?? data['sms'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'push_notifications': pushNotifications,
    'email_notifications': emailNotifications,
    'sms_notifications': smsNotifications,
  };

  AdminNotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
  }) =>
      AdminNotificationSettings(
        pushNotifications: pushNotifications ?? this.pushNotifications,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        smsNotifications: smsNotifications ?? this.smsNotifications,
      );
}