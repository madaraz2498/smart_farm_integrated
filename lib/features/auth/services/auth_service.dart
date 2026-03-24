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
//   POST /register  Form: { "name": "...", "email": "...", "password": "..." }
//   POST /login     Form: { "email": "...", "password": "..." }
//   POST /logout/{user_id}
//
// Login/register response shape:
//   { "access_token": "...", "token_type": "bearer",
//     "user": { "id": 3, "name": "...", "email": "...", "role": "farmer", ... },
//     "message": "..." }

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
      final formFields = {
        'name':     name.trim(),
        'email':    email.trim(),
        'password': password.trim(),
      };
      debugPrint('[AuthService] register body: $formFields');
      final raw = await _c.postForm('/register', formFields);

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
      final formFields = {
        'email':    email.trim(),
        'password': password.trim(),
      };
      debugPrint('[AuthService] login body: $formFields');
      final raw = await _c.postForm('/login', formFields);

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

      // Guard: if cached data is corrupted (id missing or "0"), force re-login.
      // This cleans up stale cache written before the _parse() fix.
      if (name.isEmpty && email.isEmpty) {
        debugPrint('[AuthService] restoreSession: empty name+email → clearing');
        await _clear();
        return null;
      }
      if (id.isEmpty || id == '0') {
        debugPrint('[AuthService] restoreSession: invalid id="$id" → clearing corrupted cache');
        await _clear();
        return null;
      }

      _c.setToken(token);
      debugPrint('[AuthService] session restored for $name (id=$id)');
      return UserModel(id: id, name: name.isNotEmpty ? name : email.split('@').first, email: email);
    } catch (_) {
      await _clear();
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parses the raw API response into an [AuthResponse].
  ///
  /// The backend returns a wrapper shape:
  ///   { "access_token": "...", "user": { "id": 3, "name": "...", "email": "..." }, ... }
  ///
  /// The nested "user" key MUST be checked before the generic Map branch,
  /// otherwise the top-level map (which has no id/name/email) is passed to
  /// fromJson and userId comes out as "0".
  AuthResponse _parse(dynamic raw, {String fallbackName = '', String fallbackEmail = ''}) {
    if (raw == null) {
      return AuthResponse(
          accessToken: '', userId: '', username: fallbackName, email: fallbackEmail);
    }

    if (raw is Map) {
      final Map<String, dynamic> top = Map<String, dynamic>.from(raw);

      // Nested shape: { "access_token": "...", "user": { "id": ..., ... } }
      if (top['user'] is Map) {
        final Map<String, dynamic> userFields =
        Map<String, dynamic>.from(top['user'] as Map);

        final flattened = <String, dynamic>{
          ...userFields,
          // Top-level token wins; fall back to any token key inside user block
          if (top['access_token'] != null)
            'access_token': top['access_token']
          else if (top['token'] != null)
            'access_token': top['token'],
          if (top['message'] != null) 'message': top['message'],
        };

        debugPrint('[AuthService] _parse nested → id=${flattened['id']}, name=${flattened['name']}');
        return AuthResponse.fromJson(flattened);
      }

      // Flat shape: { "access_token": "...", "id": ..., "name": "...", ... }
      debugPrint('[AuthService] _parse flat → id=${top['id'] ?? top['user_id']}, name=${top['name'] ?? top['username']}');
      return AuthResponse.fromJson(top);
    }

    return AuthResponse(
        accessToken: '', userId: '', username: fallbackName, email: fallbackEmail);
  }

  Future<AuthResult> _persist(AuthResponse resp, {required String fallbackEmail}) async {
    if (!resp.hasToken) return AuthResult.fail('No token received from server.');
    _c.setToken(resp.accessToken);
    final email = resp.email.isNotEmpty ? resp.email : fallbackEmail;
    debugPrint('[AuthService] _persist → userId=${resp.userId}, name=${resp.displayName}, email=$email');
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