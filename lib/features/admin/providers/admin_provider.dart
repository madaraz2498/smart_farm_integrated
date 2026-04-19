import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider() {
    debugPrint('[AdminProvider] Constructor called');
  }

  final AdminService _svc = AdminService.instance;
  NotificationProvider? _notif;
  String _userId = '0';

  void updateUserId(String id) {
    _userId = id;
  }

  void updateNotif(NotificationProvider? n) {
    debugPrint(
        '[AdminProvider] updateNotif called. New provider is: ${n != null ? 'Present' : 'NULL'}');
    _notif = n;
  }

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

  String getUserNameById(int id) {
    try {
      final user = _users.firstWhere((u) => u.id == id.toString());
      return user.displayName;
    } catch (_) {
      return '';
    }
  }

  // ── System Status ──────────────────────────────────────────────────────────
  Map<String, bool> _servicesStatus = {};
  Map<String, bool> _systemSettings = {};
  bool _systemLoading = false;

  Map<String, bool> get servicesStatus => _servicesStatus;
  Map<String, bool> get systemSettings => _systemSettings;
  bool get systemLoading => _systemLoading;

  // ── Load System Status ─────────────────────────────────────────────────────
  Future<void> loadSystemStatus() async {
    _systemLoading = true;
    notifyListeners();

    try {
      final status = await _svc.getSystemStatus();
      final settings = await _svc.getSystemSettings();

      // Assuming API returns something like {'plant_disease': true, ...}
      if (status['services'] is Map) {
        _servicesStatus = Map<String, bool>.from(status['services']);
      }

      if (settings['settings'] is Map) {
        _systemSettings = Map<String, bool>.from(settings['settings']);
      }
    } catch (e) {
      debugPrint('[AdminProvider] loadSystemStatus error: $e');
    } finally {
      _systemLoading = false;
      notifyListeners();
    }
  }

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
        title: 'User Deleted',
        body: 'User account ($userId) has been permanently removed.',
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
        title: active ? 'User Activated' : 'User Deactivated',
        body: 'Account for $userId is now ${active ? 'Active' : 'Inactive'}.',
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
        title: 'User Promoted',
        body: '$email is now an Administrator.',
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
      final res = await _svc.toggleService(moduleName);
      final status = res['new_status'] ?? 'updated';

      debugPrint(
          '[AdminProvider] Toggled $moduleName. Notif provider is: ${_notif != null ? 'Present' : 'NULL'}');

      _notif?.addSystemNotification(
        title: 'Module Toggled',
        body: 'AI Service ($moduleName) is now $status.',
      );

      if (_userId.isNotEmpty && _userId != '0') {
        unawaited(_notif?.fetchNotifications(userId: _userId) ?? Future.value());
      }
    } catch (e) {
      _statsError = 'Failed to toggle service.';
      notifyListeners();
    }
  }

  Future<void> toggleSystemSetting(String settingName) async {
    try {
      await _svc.toggleSystemSetting(settingName);

      debugPrint(
          '[AdminProvider] Toggled setting: $settingName. Notif provider is: ${_notif != null ? 'Present' : 'NULL'}');

      _notif?.addSystemNotification(
        title: 'Setting Changed',
        body: 'System setting ($settingName) has been modified.',
      );

      if (_userId.isNotEmpty && _userId != '0') {
        unawaited(_notif?.fetchNotifications(userId: _userId) ?? Future.value());
      }
    } catch (e) {
      _statsError = 'Failed to toggle setting.';
      notifyListeners();
    }
  }

  Future<bool> updateAdminNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      await _svc.updateAdminNotificationSettings(userId, settings);

      _notif?.addSystemNotification(
        title: 'Settings Updated',
        body: 'Admin notification settings have been updated.',
      );
      return true;
    } on ApiException catch (e) {
      _statsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _statsError = 'Failed to update admin settings.';
      notifyListeners();
      return false;
    }
  }

  void logAIConfigurationUpdate() {
    _notif?.addSystemNotification(
      title: 'AI Models Updated',
      body: 'AI service configuration has been updated.',
    );
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
