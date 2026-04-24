// lib/features/auth/providers/auth_provider.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/production_logger.dart';
import '../../../shared/models/user_model.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/models/notification_model.dart';
import '../services/auth_service.dart';

export '../services/auth_service.dart' show AuthResult;

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  final AuthService _svc = AuthService.instance;
  NotificationProvider? _notif;

  void updateNotificationProvider(NotificationProvider? notif) {
    _notif = notif;
  }

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  Uint8List? _localProfileImage;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get currentUser => _user;
  Uint8List? get localProfileImage => _localProfileImage;
  bool get isLoading => _loading;
  String? get errorMsg => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.role == UserRole.admin;
  String get displayName => _user?.displayName ?? 'Farmer';

  // ── Session restore & Refresh ─────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final u = await _svc.restoreSession();

      // Always load the locally-persisted profile image regardless of auth state
      _localProfileImage = await TokenStorage.getLocalImage();

      if (u != null) {
        _user = u;
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Background refresh to sync latest profile data from backend
        loadUserProfile();
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      ProductionLogger.auth('_init error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Refreshes the user profile from the backend.
  Future<void> loadUserProfile() async {
    if (_user == null) return;
    try {
      final updated = await _svc.refreshUserProfile(_user!);
      if (updated != null && updated != _user) {
        // If the profile image URL changed (e.g. updated from web),
        // clear the local cached image so the new server image is shown.
        if (updated.profileImg != _user?.profileImg) {
          await TokenStorage.deleteLocalImage();
          _localProfileImage = null;
        }
        _user = updated;
        notifyListeners();
      }
    } catch (e) {
      ProductionLogger.auth('loadUserProfile error: $e');
    }
  }

  // ── Update Profile ─────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    if (_user == null) return false;
    _begin();

    // Show instant local preview and persist the bytes
    if (imageBytes != null) {
      _localProfileImage = Uint8List.fromList(imageBytes);
      // Persist immediately so it survives logout → login
      await TokenStorage.saveLocalImage(_localProfileImage);
      notifyListeners();
    }

    try {
      final response = await _svc.updateProfile(
        userId: _user!.id,
        name: name,
        email: email,
        phone: phone,
        imageBytes: imageBytes,
        imageName: imageName,
      );

      if (response['success'] == true || response['message'] != null) {
        String? newImg = _user!.profileImg;

        final backendImg = response['profile_img'] as String? ??
            response['image_url'] as String? ??
            response['url'] as String?;

        if (backendImg != null && backendImg.isNotEmpty) {
          newImg = backendImg;
        } else if (imageBytes != null && newImg != null && newImg.isNotEmpty) {
          final ts = DateTime.now().millisecondsSinceEpoch;
          final base = newImg.split('?').first;
          newImg = '$base?t=$ts';
        }

        _user = _user!.copyWith(
          name: name ?? _user!.name,
          email: email ?? _user!.email,
          phone: phone ?? _user!.phone,
          profileImg: newImg,
        );

        // Persist updated name / email / profileImg URL
        final token = await TokenStorage.getToken();
        if (token != null) {
          await TokenStorage.save(
            token: token,
            userId: _user!.id,
            userName: _user!.name,
            userEmail: _user!.email,
            userRole: _user!.role == UserRole.admin ? 'admin' : 'farmer',
            profileImg: _user!.profileImg,
          );
        }

        _error = null;
        notifyListeners();
        return true;
      } else {
        // Revert local preview on failure but keep any previously saved image
        if (imageBytes != null) {
          _localProfileImage = await TokenStorage.getLocalImage();
        }
        _error = 'Failed to update profile settings.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (imageBytes != null) {
        _localProfileImage = await TokenStorage.getLocalImage();
      }
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _end();
    }
  }

  // ── Change Password ────────────────────────────────────────────────────────

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_user == null) return false;
    _begin();
    try {
      final success = await _svc.changePassword(
        userId: _user!.id,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _end();
    }
  }

  // ── Forgot/Reset Password ──────────────────────────────────────────────────

  Future<bool> forgotPassword(String email) async {
    _begin();
    try {
      final success = await _svc.forgotPassword(email);
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _end();
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _begin();
    try {
      final success = await _svc.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _end();
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _error = 'Email and password are required.';
      notifyListeners();
      return AuthResult.fail(_error!);
    }
    _begin();
    try {
      final r = await _svc.login(
          email: email.trim().toLowerCase(), password: password.trim());
      _apply(r);

      // After login, restore the locally-persisted profile image
      if (r.success) {
        _localProfileImage = await TokenStorage.getLocalImage();
        notifyListeners();
      }

      return r;
    } catch (e) {
      ProductionLogger.error('Login failed', e);
      _setError('Unexpected error. Please try again.');
      return AuthResult.fail(_error!);
    } finally {
      _end();
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _begin();
    try {
      final r =
      await _svc.register(name: name, email: email, password: password);
      _apply(r);

      if (r.success) {
        _notif?.addNotification(
          title: 'Welcome',
          body: 'Welcome to Smart Farm AI, $name!',
          type: NotificationType.user,
        );

        final id = _user?.id;
        if (id != null && id.isNotEmpty) {
        }
      }

      return r;
    } catch (e) {
      ProductionLogger.error('Register failed', e);
      _setError('Registration failed. Please try again.');
      return AuthResult.fail(_error!);
    } finally {
      _end();
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout({VoidCallback? onBeforeReset}) async {
    // Clear auth session from backend + storage (keeps local image bytes)
    await _svc.logout();
    onBeforeReset?.call();

    _user = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    // _localProfileImage intentionally NOT cleared —
    // it will be reloaded on next login from TokenStorage.getLocalImage()
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _end() {
    _loading = false;
    notifyListeners();
  }

  void _apply(AuthResult r) {
    if (r.success && r.user != null) {
      _user = r.user;
      _status = AuthStatus.authenticated;
      _error = null;
    } else {
      _error = r.error ?? 'Authentication failed.';
      _status = AuthStatus.unauthenticated;
    }
  }

  void _setError(String msg) {
    _error = msg;
    _status = AuthStatus.unauthenticated;
  }
}