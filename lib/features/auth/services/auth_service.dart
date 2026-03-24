import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../../shared/models/user_model.dart';
import '../models/auth_models.dart';

// ── AuthResult ────────────────────────────────────────────────────────────────

class AuthResult {
  const AuthResult._({required this.success, this.user, this.error});
  factory AuthResult.ok(UserModel u) => AuthResult._(success: true,  user: u);
  factory AuthResult.fail(String e)  => AuthResult._(success: false, error: e);

  final bool       success;
  final UserModel? user;
  final String?    error;
}

// ── AuthService ───────────────────────────────────────────────────────────────
// Confirmed endpoints (Swagger):
//   POST /register  JSON: { "username": "...", "email": "...", "password": "..." }
//   POST /login     JSON: { "email": "...", "password": "..." }
//   POST /logout/{user_id}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _c = ApiClient.instance;

  // ── Register ─────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] register  email=$email');
    try {
      final reqBody = RegisterRequest(
        username: name.trim(),
        email:    email.trim(),
        password: password.trim(),
      ).toJson();
      debugPrint('[AuthService] register body: $reqBody');
      final raw = await _c.post('/register', body: reqBody);

      final resp = _parse(raw, fallbackName: name.trim(), fallbackEmail: email.trim());

      if (resp.hasToken) return _persist(resp, fallbackEmail: email.trim());

      // Register gave no token → auto-login
      debugPrint('[AuthService] register: no token, auto-logging in');
      return await login(email: email.trim(), password: password.trim());
    } on ApiException catch (e) {
      if (e.isConflict)   return AuthResult.fail('Email already registered. Please sign in.');
      if (e.isValidation) return AuthResult.fail('Invalid input: ${e.message}');
      return AuthResult.fail(e.message);
    } catch (_) {
      return AuthResult.fail('Registration failed. Please try again.');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] login  email=$email');
    try {
      final reqBody = LoginRequest(email: email.trim(), password: password.trim()).toJson();
      debugPrint('[AuthService] login body: $reqBody');
      final raw = await _c.post('/login', body: reqBody);

      final resp = _parse(raw, fallbackEmail: email.trim());
      return _persist(resp, fallbackEmail: email.trim());
    } on ApiException catch (e) {
      if (e.isUnauthorized) return AuthResult.fail('Incorrect email or password.');
      if (e.isValidation)   return AuthResult.fail('Please enter a valid email and password.');
      return AuthResult.fail(e.message);
    } catch (_) {
      return AuthResult.fail('An unexpected error occurred. Please try again.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    debugPrint('[AuthService] logout');
    final stored = await TokenStorage.getUser();
    final uid    = stored['id'] ?? '';
    if (uid.isNotEmpty) {
      try { await _c.post('/logout/$uid'); } catch (_) { /* non-critical */ }
    }
    _c.setToken(null);
    await TokenStorage.clear();
  }

  // ── Session restore ───────────────────────────────────────────────────────

  Future<UserModel?> restoreSession() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) return null;

      final stored = await TokenStorage.getUser();
      final name   = stored['name']  ?? '';
      final email  = stored['email'] ?? '';
      final id     = stored['id']    ?? '';

      if (name.isEmpty && email.isEmpty) {
        await _clear();
        return null;
      }

      _c.setToken(token);
      debugPrint('[AuthService] session restored for $name');
      return UserModel(id: id, name: name.isNotEmpty ? name : email.split('@').first, email: email);
    } catch (_) {
      await _clear();
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  AuthResponse _parse(dynamic raw, {String fallbackName = '', String fallbackEmail = ''}) {
    if (raw == null) {
      return AuthResponse(
          accessToken: '', userId: '', username: fallbackName, email: fallbackEmail);
    }
    Map<String, dynamic> j;
    if (raw is Map<String, dynamic>) {
      j = raw;
    } else if (raw is Map && raw['user'] is Map) {
      j = {
        ...raw['user'] as Map<String, dynamic>,
        if (raw['access_token'] != null) 'access_token': raw['access_token'],
        if (raw['token']        != null) 'access_token': raw['token'],
      };
    } else {
      return AuthResponse(
          accessToken: '', userId: '', username: fallbackName, email: fallbackEmail);
    }
    return AuthResponse.fromJson(j);
  }

  Future<AuthResult> _persist(AuthResponse resp, {required String fallbackEmail}) async {
    if (!resp.hasToken) return AuthResult.fail('No token received from server.');
    _c.setToken(resp.accessToken);
    final email = resp.email.isNotEmpty ? resp.email : fallbackEmail;
    await TokenStorage.save(
      token:     resp.accessToken,
      userId:    resp.userId,
      userName:  resp.displayName,
      userEmail: email,
    );
    return AuthResult.ok(UserModel(id: resp.userId, name: resp.displayName, email: email));
  }

  Future<void> _clear() async {
    _c.setToken(null);
    await TokenStorage.clear();
  }
}
