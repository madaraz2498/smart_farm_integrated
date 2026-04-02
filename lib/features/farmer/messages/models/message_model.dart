// lib/features/farmer/models/message_model.dart

class FarmerMessageModel {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String content;
  final String? reply;
  final DateTime createdAt;
  final bool isReplied;

  FarmerMessageModel({
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

  factory FarmerMessageModel.fromJson(Map<String, dynamic> json) {
    return FarmerMessageModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? json['username'] ?? 'User',
      userEmail: json['user_email'] ?? json['email'] ?? '',
      subject: json['subject'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      reply: json['reply'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      isReplied: json['is_replied'] ?? (json['reply'] != null),
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
}
