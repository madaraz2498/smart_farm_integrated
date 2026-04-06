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
      reply: json['reply'] ?? json['reply_content'],
      createdAt:
          parseDate(json['created_at'] ?? json['timestamp'] ?? json['date']),
      isReplied: json['is_replied'] ??
          (json['reply'] != null || json['reply_content'] != null),
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
      isReplied: isReplied ?? this.isReplied,
    );
  }
}
