import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _svc = AdminService.instance;
  NotificationProvider? _notif;

  void updateNotif(NotificationProvider? n) => _notif = n;

  // ── Stats ─────────────────────────────────────────────────────────────────
  DashboardStats? _stats;
  bool _statsLoading = false;
  String? _statsError;

  DashboardStats? get stats => _stats;
  bool get statsLoading => _statsLoading;
  String? get statsError => _statsError;

  // ── Users ─────────────────────────────────────────────────────────────────
  List<AdminUser> _users = [];
  bool _usersLoading = false;
  String? _usersError;

  List<AdminUser> get users => List.unmodifiable(_users);
  bool get usersLoading => _usersLoading;
  String? get usersError => _usersError;

  // ── Load stats ─────────────────────────────────────────────────────────────
  Future<void> loadStats({bool force = false}) async {
    // If we have data and not forcing, just return.
    if (_stats != null && !force) return;

    // If we already have data, don't show the full-screen loader (silent refresh).
    final isSilent = _stats != null;

    if (!isSilent) {
      _statsLoading = true;
      _statsError = null;
      notifyListeners();
    }

    try {
      _stats = await _svc.getDashboardStats();
      _statsError = null; // Clear error on success
    } on ApiException catch (e) {
      _statsError = e.message;
    } catch (_) {
      _statsError = 'Failed to load statistics.';
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  // ── Load users ─────────────────────────────────────────────────────────────
  Future<void> loadUsers({bool force = false}) async {
    if (_users.isNotEmpty && !force) return;

    final isSilent = _users.isNotEmpty;

    if (!isSilent) {
      _usersLoading = true;
      _usersError = null;
      notifyListeners();
    }

    try {
      final data = await _svc.getUsersAndSummary();
      _users = data.users;
      _usersError = null; // Clear error on success
    } on ApiException catch (e) {
      _usersError = e.message;
    } catch (_) {
      _usersError = 'Failed to load users.';
    } finally {
      _usersLoading = false;
      notifyListeners();
    }
  }

  // ── User actions ───────────────────────────────────────────────────────────
  Future<bool> deleteUser(String userId) async {
    try {
      await _svc.deleteUser(userId);
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();

      _notif?.addSystemNotification(
        title: 'User Management',
        body: 'User $userId has been deleted.',
      );

      return true;
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async =>
      _toggleActive(userId, false);
  Future<bool> activateUser(String userId) async => _toggleActive(userId, true);

  Future<bool> _toggleActive(String userId, bool active) async {
    try {
      if (active) {
        await _svc.activateUser(userId);
      } else {
        await _svc.deactivateUser(userId);
      }
      final i = _users.indexWhere((u) => u.id == userId);
      if (i != -1) _users[i] = _users[i].copyWith(isActive: active);
      notifyListeners();

      _notif?.addSystemNotification(
        title: 'User Management',
        body: 'User $userId has been ${active ? 'activated' : 'deactivated'}.',
      );

      return true;
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> promoteToAdmin(String email) async {
    try {
      await _svc.promoteToAdmin(email);
      await loadUsers(force: true);

      _notif?.addSystemNotification(
        title: 'User Management',
        body: 'User $email has been promoted to Admin.',
      );

      return true;
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> promoteUserByEmail(String email) async {
    try {
      // Direct promotion by email
      return await promoteToAdmin(email);
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _usersError = 'An error occurred while promoting user.';
      notifyListeners();
      return false;
    }
  }

  // ── System Toggle Actions ──────────────────────────────────────────────────
  Future<void> toggleService(String moduleName) async {
    try {
      await _svc.toggleService(moduleName);

      _notif?.addSystemNotification(
        title: 'System Update',
        body: 'Service $moduleName has been toggled.',
      );
    } catch (e) {
      _statsError = 'Failed to toggle service.';
      notifyListeners();
    }
  }

  Future<void> toggleSystemSetting(String settingName) async {
    try {
      await _svc.toggleSystemSetting(settingName);

      _notif?.addSystemNotification(
        title: 'System Update',
        body: 'System setting $settingName has been toggled.',
      );
    } catch (e) {
      _statsError = 'Failed to toggle setting.';
      notifyListeners();
    }
  }

  // ── Refresh all ────────────────────────────────────────────────────────────
  Future<void> refreshAll() async {
    await Future.wait([loadStats(force: true), loadUsers(force: true)]);
  }

  void clearErrors() {
    _statsError = null;
    _usersError = null;
    notifyListeners();
  }
}
