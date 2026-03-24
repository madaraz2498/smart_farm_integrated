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

  @override
  String toString() => 'UserModel($id, $name, $email, $role)';
}
