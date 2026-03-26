// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
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

  void updateNotif(NotificationProvider? n) => _notif = n;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get currentUser => _user;
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
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
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
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    if (_user == null) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _svc.updateProfile(
        userId: _user!.id,
        name: name,
        email: email,
        phone: phone,
      );
      if (ok) {
        _user = _user!.copyWith(name: name, email: email);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = 'Failed to update profile.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
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
