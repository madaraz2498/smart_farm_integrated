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

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      createdAt: createdAt,
      backendTimeText: backendTimeText,
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
      'time_ago': backendTimeText,
      'is_read': isRead,
      'type': type.name,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseCreatedAt(
      json['created_at'] ??
          json['createdAt'] ??
          json['timestamp'] ??
          json['time'] ??
          json['date'],
    );

    final title = _firstNonEmptyString(json, const [
      'title',
      'notification_title',
      'notificationTitle',
      'subject',
      'heading',
      'name',
    ]);

    final body = _firstNonEmptyString(json, const [
      'body',
      'message',
      'content',
      'description',
      'details',
      'text',
    ]);

    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? json['notif_id'] ?? json['notification_id'])
              ?.toString() ??
          '',
      userId: (json['user_id'] ?? json['userId'] ?? json['uid'])?.toString() ?? '',
      title: title ?? '',
      body: body ?? '',
      createdAt: createdAt,
      backendTimeText: _parseBackendTimeText(json),
      isRead: _parseRead(json),
      type: _parseType(
        (json['type'] ?? json['category'] ?? json['kind'])?.toString(),
      ),
    );
  }

  static bool _parseRead(Map<String, dynamic> json) {
    final raw = json['is_read'] ?? json['isRead'] ?? json['read'] ?? json['seen'];
    if (raw is bool) return raw;
    final s = raw?.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static DateTime _parseCreatedAt(dynamic raw) {
    if (raw == null) return DateTime.now();
    final value = raw.toString().trim();
    if (value.isEmpty) return DateTime.now();

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return DateTime.now();

    // Backend can send UTC timestamps (with Z or offset). Always display in local time.
    if (parsed.isUtc || value.endsWith('Z') || value.contains('+')) {
      return parsed.toLocal();
    }
    return parsed;
  }

  static String? _parseBackendTimeText(Map<String, dynamic> json) {
    const keys = [
      'time_ago',
      'timeAgo',
      'relative_time',
      'relativeTime',
      'created_at_human',
      'createdAtHuman',
      'display_time',
      'displayTime',
    ];
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final v = json[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Parses a backend time_ago string (e.g. "2 hours ago", "منذ 3 أيام")
  /// and returns a normalized Duration so the UI can re-format it in the
  /// user's current locale.  Returns null if the string cannot be parsed.
  static Duration? parseBackendTimeToDuration(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final t = text.trim().toLowerCase();

    // English patterns: "X minute(s) ago", "X hour(s) ago", "X day(s) ago"
    final minEn = RegExp(r'(\d+)\s*minute').firstMatch(t);
    if (minEn != null) return Duration(minutes: int.parse(minEn.group(1)!));
    final hrEn = RegExp(r'(\d+)\s*hour').firstMatch(t);
    if (hrEn != null) return Duration(hours: int.parse(hrEn.group(1)!));
    final dayEn = RegExp(r'(\d+)\s*day').firstMatch(t);
    if (dayEn != null) return Duration(days: int.parse(dayEn.group(1)!));

    // Arabic patterns: "منذ X د/دقيقة", "منذ X س/ساعة", "منذ X يوم"
    final minAr = RegExp(r'(\d+)\s*(د|دقيقة)').firstMatch(t);
    if (minAr != null) return Duration(minutes: int.parse(minAr.group(1)!));
    final hrAr = RegExp(r'(\d+)\s*(س|ساعة)').firstMatch(t);
    if (hrAr != null) return Duration(hours: int.parse(hrAr.group(1)!));
    final dayAr = RegExp(r'(\d+)\s*يوم').firstMatch(t);
    if (dayAr != null) return Duration(days: int.parse(dayAr.group(1)!));

    if (t == 'just now' || t == 'الآن') return Duration.zero;
    return null;
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