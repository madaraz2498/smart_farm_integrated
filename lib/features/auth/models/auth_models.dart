// Auth request/response models.
// Swagger schemas: Body_login_login_post, Body_register_register_post
//
// ⚠️  Both endpoints use JSON (Content-Type: application/json)
//     POST /login    → { "email": "...", "password": "..." }
//     POST /register → { "username": "...", "email": "...", "password": "..." }

import 'package:smart_farm/shared/models/user_model.dart';

class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email, password;

  /// JSON body — used with ApiClient.post()
  Map<String, dynamic> toJson() => {
        'email':    email,
        'password': password,
      };
}

class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });
  final String username, email, password;

  /// JSON body — used with ApiClient.post()
  Map<String, dynamic> toJson() => {
        'username': username,
        'email':    email,
        'password': password,
      };
}

/// Unified response from POST /login and POST /register.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.userId,
    required this.username,
    required this.email,
    this.role = 'farmer',
    this.profileImg,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        accessToken: j['access_token'] as String? ?? j['token'] as String? ?? '',
        userId:      (j['user_id'] ?? j['id'] ?? 0).toString(),
        username:    j['username']  as String? ?? j['name'] as String? ?? '',
        email:       j['email']     as String? ?? '',
        role:        j['role']      as String? ?? 'farmer',
        profileImg:  j['profile_img'] as String?,
        message:     j['message']   as String? ?? j['detail'] as String?,
      );

  final String  accessToken, userId, username, email, role;
  final String? profileImg;
  final String? message;

  bool   get hasToken    => accessToken.isNotEmpty;
  String get displayName => username.isNotEmpty ? username : email.split('@').first;
  UserRole get userRole  => role.toLowerCase() == 'admin' ? UserRole.admin : UserRole.farmer;
}
