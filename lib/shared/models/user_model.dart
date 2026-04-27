// lib/shared/models/user_model.dart
enum UserRole { farmer, admin, super_admin }

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.farmer,
    this.phone,
    this.profileImg,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? profileImg;

  bool get isAdmin => role == UserRole.admin || role == UserRole.super_admin;
  bool get isSuperAdmin => role == UserRole.super_admin;
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? profileImg,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        phone: phone ?? this.phone,
        profileImg: profileImg ?? this.profileImg,
      );

  factory UserModel.fromJson(Map<String, dynamic> j) {
    final roleStr = (j['role'] as String? ?? 'farmer').toLowerCase();
    UserRole role;
    switch (roleStr) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'super_admin':
        role = UserRole.super_admin;
        break;
      default:
        role = UserRole.farmer;
    }
    return UserModel(
      id: (j['id'] ?? j['user_id'] ?? 0).toString(),
      name: j['name'] as String? ?? j['username'] as String? ?? '',
      email: j['email'] as String? ?? '',
      role: role,
      phone: j['phone'] as String?,
      profileImg: j['profile_img'] as String?,
    );
  }

  @override
  String toString() => 'UserModel($id, $name, $email, $role)';
}
