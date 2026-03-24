// lib/shared/models/user_model.dart
enum UserRole { farmer, admin }

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.farmer,
  });

  final String   id;
  final String   name;
  final String   email;
  final UserRole role;

  bool   get isAdmin     => role == UserRole.admin;
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  UserModel copyWith({String? id, String? name, String? email, UserRole? role}) =>
      UserModel(
        id:    id    ?? this.id,
        name:  name  ?? this.name,
        email: email ?? this.email,
        role:  role  ?? this.role,
      );

  factory UserModel.fromJson(Map<String, dynamic> j) {
    final roleStr = (j['role'] as String? ?? 'farmer').toLowerCase();
    return UserModel(
      id:    (j['id'] ?? j['user_id'] ?? 0).toString(),
      name:  j['name']  as String? ?? j['username'] as String? ?? '',
      email: j['email'] as String? ?? '',
      role:  roleStr == 'admin' ? UserRole.admin : UserRole.farmer,
    );
  }

  @override
  String toString() => 'UserModel($id, $name, $email, $role)';
}
