// lib/shared/models/message_model.dart

class MessageModel {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String content;
  final String? reply;
  final DateTime createdAt;
  final DateTime? repliedAt;
  final bool isReplied;

  MessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.content,
    this.reply,
    required this.createdAt,
    this.repliedAt,
    this.isReplied = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      try {
        final dt = DateTime.parse(d.toString());
        return dt.isUtc ? dt.toLocal() : dt;
      } catch (_) {
        return DateTime.now();
      }
    }

    // Try all possible reply field names from API
    final replyValue = json['reply'] ??
        json['reply_content'] ??
        json['admin_reply'] ??
        json['response'] ??
        json['answer'] ??
        json['reply_message'] ??
        json['reply_text'];

    // Convert to String? safely
    final String? replyStr = (replyValue != null && replyValue.toString().trim().isNotEmpty)
        ? replyValue.toString()
        : null;

    return MessageModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ??
          json['username'] ??
          json['user']?['username'] ??
          json['user']?['name'] ??
          'User',
      userEmail:
      json['user_email'] ?? json['email'] ?? json['user']?['email'] ?? '',
      subject: json['subject'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      reply: replyStr,
      createdAt:
      parseDate(json['created_at'] ?? json['timestamp'] ?? json['date']),
      repliedAt: json['reply_at'] != null ||
          json['replied_at'] != null ||
          json['reply_time'] != null
          ? parseDate(json['reply_at'] ??
          json['replied_at'] ??
          json['reply_time'])
          : (replyStr != null ? parseDate(json['updated_at']) : null),
      isReplied: json['is_replied'] == true ||
          json['is_replied'] == 1 ||
          json['status'] == 'replied' ||
          json['status'] == 'answered' ||
          replyStr != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'subject': subject,
      'content': content,
      'reply': reply,
      'created_at': createdAt.toIso8601String(),
      'replied_at': repliedAt?.toIso8601String(),
      'is_replied': isReplied,
    };
  }

  MessageModel copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userEmail,
    String? subject,
    String? content,
    String? reply,
    DateTime? createdAt,
    DateTime? repliedAt,
    bool? isReplied,
  }) {
    return MessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      reply: reply ?? this.reply,
      createdAt: createdAt ?? this.createdAt,
      repliedAt: repliedAt ?? this.repliedAt,
      isReplied: isReplied ?? this.isReplied,
    );
  }
}