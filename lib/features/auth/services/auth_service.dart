import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../admin/services/admin_service.dart';
import '../models/auth_models.dart';

// ── AuthResult ────────────────────────────────────────────────────────────────

class AuthResult {
  const AuthResult._({required this.success, this.user, this.error});
  factory AuthResult.ok(UserModel u) => AuthResult._(success: true, user: u);
  factory AuthResult.fail(String e) => AuthResult._(success: false, error: e);

  final bool success;
  final UserModel? user;
  final String? error;
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
        'name': name.trim(),
        'email': email.trim(),
        'password': password.trim(),
      };
      debugPrint('[AuthService] register body: $formFields');
      final raw = await _c.postForm('/register', formFields);

      final resp =
          _parse(raw, fallbackName: name.trim(), fallbackEmail: email.trim());

      if (resp.hasToken) return _persist(resp, fallbackEmail: email.trim());

      // Register gave no token → auto-login
      debugPrint('[AuthService] register: no token, auto-logging in');
      return await login(email: email.trim(), password: password.trim());
    } on ApiException catch (e) {
      if (e.isConflict)
        return AuthResult.fail('Email already registered. Please sign in.');
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
        'email': email.trim(),
        'password': password.trim(),
      };
      debugPrint('[AuthService] login body: $formFields');
      final raw = await _c.postForm('/login', formFields);

      final resp = _parse(raw, fallbackEmail: email.trim());
      return _persist(resp, fallbackEmail: email.trim());
    } on ApiException catch (e) {
      if (e.isUnauthorized)
        return AuthResult.fail('Incorrect email or password.');
      if (e.isValidation)
        return AuthResult.fail('Please enter a valid email and password.');
      return AuthResult.fail(e.message);
    } catch (_) {
      return AuthResult.fail('An unexpected error occurred. Please try again.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    debugPrint('[AuthService] logout');
    final stored = await TokenStorage.getUser();
    final uid = stored['id'] ?? '';
    if (uid.isNotEmpty) {
      try {
        await _c.post('/logout/$uid');
      } catch (_) {
        /* non-critical */
      }
    }
    _c.setToken(null);
    await TokenStorage.clear();
  }

  // ── Update Profile ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    try {
      final fields = {
        if (name != null) 'full_name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };

      final response = await _c.putMultipart(
        '/save-all-settings/$userId',
        fileField: 'profile_img',
        fileBytes: imageBytes,
        fileName: imageName,
        fields: fields,
      );

      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'success': true};
    } catch (e) {
      debugPrint('[AuthService] updateProfile error: $e');
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _c.postForm('/change-password/$userId', {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      return true;
    } catch (e) {
      debugPrint('[AuthService] changePassword error: $e');
      rethrow;
    }
  }

  // ── Session restore ───────────────────────────────────────────────────────

  Future<UserModel?> restoreSession() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) return null;

      final stored = await TokenStorage.getUser();
      final name = stored['name'] ?? '';
      final email = stored['email'] ?? '';
      final id = stored['id'] ?? '';
      final role = (stored['role'] ?? 'farmer').toLowerCase();
      final profileImg = stored['profile_img'];

      // Guard: if cached data is corrupted (id missing or "0"), force re-login.
      if (name.isEmpty && email.isEmpty) {
        debugPrint('[AuthService] restoreSession: empty name+email → clearing');
        await _clear();
        return null;
      }
      if (id.isEmpty || id == '0') {
        debugPrint(
            '[AuthService] restoreSession: invalid id="$id" → clearing corrupted cache');
        await _clear();
        return null;
      }

      _c.setToken(token);
      debugPrint(
          '[AuthService] session restored for $name (id=$id, role=$role)');

      // Sanitize profile image URL: if it contains the broken guessed path, clear it.
      String? sanitizedImg = profileImg;
      if (sanitizedImg != null && sanitizedImg.contains('/uploads/users/')) {
        debugPrint(
            '[AuthService] sanitizing broken profile path: $sanitizedImg');
        sanitizedImg = null;
      }

      return UserModel(
        id: id,
        name: name.isNotEmpty ? name : email.split('@').first,
        email: email,
        role: role == 'admin' ? UserRole.admin : UserRole.farmer,
        profileImg: sanitizedImg,
      );
    } catch (_) {
      await _clear();
      return null;
    }
  }

  /// Fetches the latest user profile data from the backend to refresh stale cached data.
  /// This is critical to resolve 404 errors on profile images if the URL changed.
  Future<UserModel?> refreshUserProfile(UserModel current) async {
    try {
      debugPrint('[AuthService] refreshUserProfile for ${current.id}');

      // If admin, we can fetch the user list to find the current user's latest info.
      if (current.role == UserRole.admin) {
        final adminSvc = AdminService.instance;
        final data = await adminSvc.getUsersAndSummary();
        final found = data.users.firstWhere((u) => u.id == current.id);

        final updated = current.copyWith(
          name: found.username,
          email: found.email,
          profileImg: found.profileImg,
        );

        // Update cache
        await _persistUpdated(updated);
        return updated;
      }

      // If farmer, we could try GET /user/$id or a similar endpoint.
      // Based on common patterns, let's try to fetch user details.
      return current;
    } catch (e) {
      debugPrint('[AuthService] refreshUserProfile non-critical error: $e');
      return current;
    }
  }

  Future<void> _persistUpdated(UserModel u) async {
    final token = await TokenStorage.getToken();
    if (token == null) return;
    await TokenStorage.save(
      token: token,
      userId: u.id,
      userName: u.name,
      userEmail: u.email,
      userRole: u.role == UserRole.admin ? 'admin' : 'farmer',
      profileImg: u.profileImg,
    );
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
  AuthResponse _parse(dynamic raw,
      {String fallbackName = '', String fallbackEmail = ''}) {
    if (raw == null) {
      return AuthResponse(
          accessToken: '',
          userId: '',
          username: fallbackName,
          email: fallbackEmail);
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

        debugPrint(
            '[AuthService] _parse nested → id=${flattened['id']}, name=${flattened['name']}');
        return AuthResponse.fromJson(flattened);
      }

      // Flat shape: { "access_token": "...", "id": ..., "name": "...", ... }
      debugPrint(
          '[AuthService] _parse flat → id=${top['id'] ?? top['user_id']}, name=${top['name'] ?? top['username']}');
      return AuthResponse.fromJson(top);
    }

    return AuthResponse(
        accessToken: '',
        userId: '',
        username: fallbackName,
        email: fallbackEmail);
  }

  Future<AuthResult> _persist(AuthResponse resp,
      {required String fallbackEmail}) async {
    if (!resp.hasToken)
      return AuthResult.fail('No token received from server.');
    _c.setToken(resp.accessToken);
    final email = resp.email.isNotEmpty ? resp.email : fallbackEmail;
    debugPrint(
        '[AuthService] _persist → userId=${resp.userId}, name=${resp.displayName}, email=$email, role=${resp.role}');
    await TokenStorage.save(
      token: resp.accessToken,
      userId: resp.userId,
      userName: resp.displayName,
      userEmail: email,
      userRole: resp.role,
      profileImg: resp.profileImg,
    );
    return AuthResult.ok(UserModel(
      id: resp.userId,
      name: resp.displayName,
      email: email,
      role: resp.userRole,
      profileImg: resp.profileImg,
    ));
  }

  Future<void> _clear() async {
    _c.setToken(null);
    await TokenStorage.clear();
  }
}
