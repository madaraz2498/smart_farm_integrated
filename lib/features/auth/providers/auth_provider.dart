// lib/features/auth/providers/auth_provider.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/network/token_storage.dart';
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

  Future<void> _init() async {
    try {
      final u = await _svc.restoreSession();
      if (u != null) {
        _user = u;
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Background refresh to fix potential 404 on profile image
        _svc.refreshUserProfile(u).then((updated) {
          if (updated != null && updated != _user) {
            _user = updated;
            notifyListeners();
          }
        });
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] _init error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    if (_user == null) return false;
    _begin();

    // Store local bytes for instant preview if available
    if (imageBytes != null) {
      _localProfileImage = Uint8List.fromList(imageBytes);
      notifyListeners();
    }

    try {
      final success = await _svc.updateProfile(
        userId: _user!.id,
        name: name,
        email: email,
        phone: phone,
        imageBytes: imageBytes,
        imageName: imageName,
      );

      if (success) {
        // Handle profile image update with cache busting ONLY if we have a real URL
        String? newImg = _user!.profileImg;
        if (imageBytes != null && newImg != null && newImg.isNotEmpty) {
          final ts = DateTime.now().millisecondsSinceEpoch;
          final base = newImg.split('?').first;
          newImg = '$base?t=$ts';
        } else if (imageBytes != null) {
          // If we uploaded bytes but don't have a URL yet, keep it null
          // the local bytes preview will take precedence in the UI.
          newImg = null;
        }

        // Optimistically update local user model
        _user = _user!.copyWith(
          name: name ?? _user!.name,
          email: email ?? _user!.email,
          phone: phone ?? _user!.phone,
          profileImg: newImg,
        );

        // Persist updated data locally
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
        notifyListeners(); // Force UI update across app
        return true;
      } else {
        _localProfileImage = null; // Clear preview on failure
        _error = 'Failed to update profile settings.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _localProfileImage = null; // Clear preview on error
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _end();
    }
  }

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

  Future<AuthResult> login(
      {required String email, required String password}) async {
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
      return r;
    } catch (_) {
      _setError('Unexpected error. Please try again.');
      return AuthResult.fail(_error!);
    } finally {
      _end();
    }
  }

  Future<AuthResult> register(
      {required String name,
      required String email,
      required String password}) async {
    _begin();
    try {
      final r =
          await _svc.register(name: name, email: email, password: password);
      _apply(r);

      if (r.success) {
        _notif?.addLocalNotification(
          title: 'Welcome',
          body: 'Welcome to Smart Farm AI, $name!',
          type: NotificationType.user,
        );
      }

      return r;
    } catch (_) {
      _setError('Registration failed. Please try again.');
      return AuthResult.fail(_error!);
    } finally {
      _end();
    }
  }

  Future<void> logout({VoidCallback? onBeforeReset}) async {
    await _svc.logout();
    onBeforeReset?.call();
    _user = null;
    _localProfileImage = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

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
