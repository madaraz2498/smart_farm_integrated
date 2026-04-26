import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/production_logger.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/models/notification_model.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider() {
    ProductionLogger.info('Constructor called');
  }

  final AdminService _svc = AdminService.instance;
  NotificationProvider? _notif;
  String _userId = '0';
  String _locale = 'en'; // tracks current app language for localised notifications

  void updateUserId(String id) {
    _userId = id;
  }

  void updateNotif(NotificationProvider? n) {
    ProductionLogger.info('[AdminProvider] updateNotif called. New provider is: ${n != null ? 'Present' : 'NULL'}');
    _notif = n;
  }

  void updateLocale(String languageCode) {
    _locale = languageCode;
  }

  // ── Localised notification helpers ────────────────────────────────────────

  bool get _isArabic => _locale == 'ar';

  /// Returns [ar] when the app is in Arabic, otherwise [en].
  String _t(String en, String ar) => _isArabic ? ar : en;

  /// Fetches fresh notifications from the backend so the badge count and
  /// feed update immediately after a service-toggle or setting change.
  void _refreshNotifications() {
    if (_notif != null && _userId.isNotEmpty && _userId != '0') {
      _notif!.fetchNotifications(userId: _userId, showLoading: false, force: true);
    }
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
    return _users
        .cast<AdminUser?>()
        .firstWhere((u) => u?.id == id.toString(), orElse: () => null)
        ?.displayName ?? '';
  }

  /// Returns the email address for a user by their integer id.
  /// Returns an empty string if the user is not found.
  String getUserEmailById(int id) {
    return _users
        .cast<AdminUser?>()
        .firstWhere((u) => u?.id == id.toString(), orElse: () => null)
        ?.email ?? '';
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
      ProductionLogger.info('loadSystemStatus error: $e');
    } finally {
      _systemLoading = false;
      notifyListeners();
    }
  }

  // ── Load stats ─────────────────────────────────────────────────────────────
  Future<void> loadStats({bool force = false}) async {
    // If we have data and not forcing, just return.
    if (_stats != null && !force) return;
    // Prevent concurrent duplicate calls.
    if (_statsLoading) return;

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
    } catch (e) {
      ProductionLogger.error('loadStats failed', e);
      _statsError = 'Failed to load statistics.';
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  // ── Load users ─────────────────────────────────────────────────────────────
  Future<void> loadUsers({bool force = false}) async {
    if (_users.isNotEmpty && !force) return;
    // Prevent concurrent duplicate calls.
    if (_usersLoading) return;

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
    } catch (e) {
      ProductionLogger.error('loadUsers failed', e);
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
        body: 'User account ($userId) has been permanently removed.',);

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
      final rawStatus = (res['new_status'] ?? 'updated').toString();
      final serviceName = (res['service'] ?? moduleName).toString();

      final isOnline = rawStatus.toLowerCase() == 'online';

      ProductionLogger.info('[AdminProvider] Toggled $moduleName ($serviceName) -> $rawStatus. Notif provider: ${_notif != null ? 'Present' : 'NULL'}');

      // Add a localised local notification immediately so the badge updates
      _notif?.addLocalNotification(
        title: _t('Service Alert 🚜', 'تنبيه الخدمات 🚜'),
        body: isOnline
            ? _t('✅ Service ($serviceName) started successfully.', 'تم تشغيل ✅ خدمة ($serviceName) بنجاح.')
            : _t('❌ Service ($serviceName) stopped successfully.', 'تم إيقاف ❌ خدمة ($serviceName) بنجاح.'),
        type: NotificationType.system,
      );

      // Then fetch from backend so the feed stays in sync
      _refreshNotifications();
    } catch (e) {
      _statsError = 'Failed to toggle service.';
      notifyListeners();
    }
  }

  Future<void> toggleSystemSetting(String settingName) async {
    try {
      await _svc.toggleSystemSetting(settingName);

      ProductionLogger.info('[AdminProvider] Toggled setting: $settingName. Notif provider: ${_notif != null ? 'Present' : 'NULL'}');

      _notif?.addLocalNotification(
        title: _t('System Setting Changed', 'تغيير إعداد النظام'),
        body: _t('Setting ($settingName) has been updated.', 'تم تحديث الإعداد ($settingName).'),
        type: NotificationType.system,
      );

      _refreshNotifications();
    } catch (e) {
      _statsError = 'Failed to toggle setting.';
      notifyListeners();
    }
  }

  Future<bool> updateAdminNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      await _svc.updateAdminNotificationSettings(userId, settings);

      _notif?.addLocalNotification(
        title: _t('Settings Updated', 'تم تحديث الإعدادات'),
        body: _t('Admin notification settings have been updated.', 'تم تحديث إعدادات إشعارات المسؤول.'),
        type: NotificationType.system,
      );
      _refreshNotifications();
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
