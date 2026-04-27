// lib/features/notifications/models/notification_model.dart

enum NotificationType { system, report, user, chatbot }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? backendTimeText;
  final bool isRead;
  final NotificationType type;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.backendTimeText,
    this.isRead = false,
    required this.type,
  });

  AppNotification copyWith({bool? isRead, String? title, String? body}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      backendTimeText: backendTimeText,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'body': body,
    'created_at': createdAt.toIso8601String(),
    'time_ago': backendTimeText,
    'is_read': isRead,
    'type': type.name,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseCreatedAt(json['created_at']);
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: ((json['body'] as String?)?.trim().isNotEmpty == true
          ? json['body'] as String
          : (json['description'] as String?)?.trim().isNotEmpty == true
          ? json['description'] as String
          : (json['message'] as String?)?.trim()) ?? '',
      createdAt: createdAt,
      backendTimeText: _parseBackendTimeText(json),
      isRead: json['is_read'] ?? json['read'] ?? false,
      type: _parseType(json['type']),
    );
  }

  static DateTime _parseCreatedAt(dynamic raw) {
    if (raw == null) return DateTime.now();
    final value = raw.toString().trim();
    if (value.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return (parsed.isUtc || value.endsWith('Z') || value.contains('+'))
          ? parsed.toLocal()
          : parsed;
    }
    final ampmMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (ampmMatch != null) {
      final year = int.parse(ampmMatch.group(1)!);
      final month = int.parse(ampmMatch.group(2)!);
      final day = int.parse(ampmMatch.group(3)!);
      int hour = int.parse(ampmMatch.group(4)!);
      final minute = int.parse(ampmMatch.group(5)!);
      final isPm = ampmMatch.group(6)!.toUpperCase() == 'PM';
      if (hour == 12) { hour = isPm ? 12 : 0; } else if (isPm) { hour += 12; }
      return DateTime(year, month, day, hour, minute);
    }
    return DateTime.now();
  }

  static String? _parseBackendTimeText(Map<String, dynamic> json) {
    const keys = ['time_ago', 'timeAgo', 'relative_time', 'relativeTime',
      'created_at_human', 'createdAtHuman', 'display_time', 'displayTime'];
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static NotificationType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'report': return NotificationType.report;
      case 'user': return NotificationType.user;
      case 'chatbot': return NotificationType.chatbot;
      default: return NotificationType.system;
    }
  }

  static Duration? parseBackendTimeToDuration(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final t = text.trim().toLowerCase();

    final minEn = RegExp(r'(\d+)\s*minute').firstMatch(t);
    if (minEn != null) return Duration(minutes: int.parse(minEn.group(1)!));
    final hrEn = RegExp(r'(\d+)\s*hour').firstMatch(t);
    if (hrEn != null) return Duration(hours: int.parse(hrEn.group(1)!));
    final dayEn = RegExp(r'(\d+)\s*day').firstMatch(t);
    if (dayEn != null) return Duration(days: int.parse(dayEn.group(1)!));

    final minAr = RegExp(r'(\d+)\s*(د|دقيقة)').firstMatch(t);
    if (minAr != null) return Duration(minutes: int.parse(minAr.group(1)!));
    final hrAr = RegExp(r'(\d+)\s*(س|ساعة)').firstMatch(t);
    if (hrAr != null) return Duration(hours: int.parse(hrAr.group(1)!));
    final dayAr = RegExp(r'(\d+)\s*يوم').firstMatch(t);
    if (dayAr != null) return Duration(days: int.parse(dayAr.group(1)!));

    if (t == 'just now' || t == 'الآن') return Duration.zero;
    return null;
  }
}

// ── Farmer Settings ──────────────────────────────────────────────────────────
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
    final data = json['settings'] is Map
        ? json['settings'] as Map<String, dynamic>
        : json;
    return FarmerNotificationSettings(
      emailNotificationsFarmer:
      data['email_notifications_farmer'] ?? data['email_notif'] ?? false,
      analysisCompletionAlerts:
      data['analysis_completion_alerts'] ?? data['analysis_alt'] ?? true,
      weeklyReportSummary:
      data['weekly_report_summary'] ?? data['weekly_alt'] ?? false,
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

// ── Admin Settings ───────────────────────────────────────────────────────────
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
      pushNotifications:
      data['push_notifications'] ?? data['admin_push'] ?? data['push'] ?? true,
      emailNotifications:
      data['email_notifications'] ?? data['admin_email'] ?? data['email'] ?? true,
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