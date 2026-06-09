import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/request_cache.dart';
import '../../../core/utils/production_logger.dart';
import '../../../core/utils/app_lifecycle_manager.dart'; // AppBootstrapController, PageLifecycleManager, RequestDeduplicator
import '../../notifications/providers/notification_provider.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

/// AdminProvider - minimal refactor to fix critical bugs while keeping existing architecture
class AdminProvider extends ChangeNotifier {
  AdminProvider() {
    ProductionLogger.info('[AdminProvider] Constructor called');
  }

  final AdminService _svc = AdminService.instance;
  final RequestCache _cache = RequestCache.instance;
  NotificationProvider? _notif;
  String _userId = '0';
  String _locale = 'en';

  // Thread-safe initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Thread-safe notification refresh with simple throttling
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  static const Duration _throttleDuration = Duration(seconds: 2);

  // Stats state
  DashboardStats? _stats;
  bool _statsLoading = false;
  String? _statsError;

  // Users state
  List<AdminUser> _users = [];
  int _totalUsersCount = 0;
  int _activeUsersCount = 0;
  bool _usersLoading = false;
  String? _usersError;

  // System state
  Map<String, bool?> _servicesStatus = {
    'plant_disease': true,
    'animal_weight': true,
    'crop_rec': true,
    'soil_analysis': true,
    'fruit_quality': true,
    'chatbot': true,
  };
  Map<String, bool?> _systemSettings = {
    'email_notifications': true,
    'maintenance_mode': false,
    'auto_backup': true,
  };
  SystemStatus? _statusDetails;
  bool _systemLoading = false;

  // Getters for backward compatibility
  DashboardStats? get stats => _stats;
  bool get statsLoading => _statsLoading;
  String? get statsError => _statsError;

  List<AdminUser> get users => List.unmodifiable(_users);
  bool get usersLoading => _usersLoading;
  String? get usersError => _usersError;

  Map<String, bool?> get servicesStatus => Map.unmodifiable(_servicesStatus);
  Map<String, bool?> get systemSettings => Map.unmodifiable(_systemSettings);
  SystemStatus? get statusDetails => _statusDetails;
  bool get systemLoading => _systemLoading;

  /// Update dependencies (called from ProxyProvider).
  /// Data loading is intentionally deferred — screens call [initializeIfNeeded]
  /// or individual load methods in their own initState so that the app startup
  /// never triggers a cascade of API calls before any page is even visible.
  void updateUserId(String id) {
    if (_userId == id) return;

    ProductionLogger.info('[AdminProvider] updateUserId: $_userId -> $id');
    _userId = id;

    // Reset initialized flag so the next explicit screen-level call re-fetches
    // for the new user, but do NOT auto-fetch here (lazy loading).
    if (id.isNotEmpty && id != '0') {
      _isInitialized = false;
    }
  }

  void updateNotif(NotificationProvider? n) {
    if (_notif == n) return;

    ProductionLogger.info('[AdminProvider] updateNotif called');
    _notif = n;
  }

  void updateLocale(String languageCode) {
    if (_locale == languageCode) return;

    ProductionLogger.info(
        '[AdminProvider] updateLocale: $_locale -> $languageCode');
    _locale = languageCode;
  }

  // ── Public API: Page-driven loading ──────────────────────────────────────────

  /// Load stats only if admin module is unlocked and not yet loaded.
  Future<void> loadStatsIfNeeded() {
    if (!AppBootstrapController.instance
        .isModuleUnlocked(AppBootstrapController.kAdmin)) {
      return Future.value();
    }
    return loadStats(force: false);
  }

  /// Load users only if admin module is unlocked and not yet loaded.
  Future<void> loadUsersIfNeeded() {
    if (!AppBootstrapController.instance
        .isModuleUnlocked(AppBootstrapController.kAdmin)) {
      return Future.value();
    }
    return loadUsers(force: false);
  }

  /// Load system status only if system module is unlocked and not yet loaded.
  Future<void> loadSystemIfNeeded() {
    if (!AppBootstrapController.instance
        .isModuleUnlocked(AppBootstrapController.kSystem)) {
      return Future.value();
    }
    return loadSystemStatus(forceRefresh: false);
  }

  // ── Fixed Initialization - Single Source of Truth ─────────────────────────────
  Future<void> initializeIfNeeded() async {
    // Prevent duplicate initialization - FIXED
    if (_isInitialized ||
        _isInitializing ||
        _userId.isEmpty ||
        _userId == '0') {
      return;
    }

    _isInitializing = true;
    ProductionLogger.info(
        '[AdminProvider] Initializing data for user: $_userId');

    try {
      // Load all data in parallel - FIXED: prevents duplicate API calls
      await Future.wait([
        loadStats(force: false),
        loadUsers(force: false),
        loadSystemStatus(forceRefresh: false),
      ]);

      _isInitialized = true;
      ProductionLogger.info('[AdminProvider] Initialization completed');
    } catch (e) {
      ProductionLogger.error('[AdminProvider] Initialization failed', e);
      _isInitialized = false; // Allow retry on failure
    } finally {
      _isInitializing = false;
    }
  }

  // ── Fixed Data Loading Methods ───────────────────────────────────────────────
  Future<void> loadStats({bool force = false}) async {
    // ── Bootstrap gate ───────────────────────────────────────────────────────
    if (!force &&
        !AppBootstrapController.instance
            .isModuleUnlocked(AppBootstrapController.kAdmin)) {
      ProductionLogger.info(
          '[AdminProvider] Admin module locked — skipping loadStats');
      return;
    }

    // Prevent concurrent duplicate calls.
    if (_statsLoading) return;
    if (_stats != null && !force) return;

    // Silent refresh: if we already have data, skip loading spinner rebuild.
    final isSilentRefresh = _stats != null;

    if (!isSilentRefresh) {
      _statsLoading = true;
      _statsError = null;
      notifyListeners();
    }

    try {
      // Use RequestDeduplicator to merge concurrent calls.
      _stats = await RequestDeduplicator.instance.execute(
        key: 'admin_stats',
        fetcher: () => _svc.getDashboardStats(),
        force: force,
      );

      // Fallback: If stats returned 0 users but we have a cached user count, use it.
      if (_stats != null && _stats!.totalUsers == 0 && _totalUsersCount > 0) {
        _stats = _stats!.copyWith(
          totalUsers: _totalUsersCount,
          activeUsers: _activeUsersCount,
        );
      }

      _statsError = null;
    } on ApiException catch (e) {
      _statsError = e.message;
    } catch (e) {
      ProductionLogger.error('[AdminProvider] loadStats failed', e);
      _statsError = 'Failed to load statistics.';
    } finally {
      _statsLoading = false;
      notifyListeners(); // single notify at the end — batches all state changes
    }
  }

  Future<void> loadUsers({bool force = false}) async {
    // ── Bootstrap gate ───────────────────────────────────────────────────────
    if (!force &&
        !AppBootstrapController.instance
            .isModuleUnlocked(AppBootstrapController.kAdmin)) {
      ProductionLogger.info(
          '[AdminProvider] Admin module locked — skipping loadUsers');
      return;
    }

    // Prevent concurrent duplicate calls.
    if (_usersLoading) return;
    if (_users.isNotEmpty && !force) return;

    // Silent refresh: if we already have data, skip loading spinner rebuild.
    final isSilentRefresh = _users.isNotEmpty;

    if (!isSilentRefresh) {
      _usersLoading = true;
      _usersError = null;
      notifyListeners();
    }

    try {
      // Use RequestDeduplicator to merge concurrent calls.
      final data = await RequestDeduplicator.instance.execute(
        key: 'admin_users',
        fetcher: () => _svc.getUsersAndSummary(),
        force: force,
      );
      _users = data.users;
      _totalUsersCount = data.totalUsers;
      _activeUsersCount = data.activeUsers;

      // If stats are already loaded but users count is 0, update it from here
      if (_stats != null && _stats!.totalUsers == 0 && _totalUsersCount > 0) {
        _stats = _stats!.copyWith(
          totalUsers: _totalUsersCount,
          activeUsers: _activeUsersCount,
        );
      }

      _usersError = null;
    } on ApiException catch (e) {
      _usersError = e.message;
    } catch (e) {
      ProductionLogger.error('[AdminProvider] loadUsers failed', e);
      _usersError = 'Failed to load users.';
    } finally {
      _usersLoading = false;
      notifyListeners(); // single notify at the end
    }
  }

  Future<void> loadSystemStatus({bool forceRefresh = false}) async {
    // ── Bootstrap gate ───────────────────────────────────────────────────────
    if (!forceRefresh &&
        !AppBootstrapController.instance
            .isModuleUnlocked(AppBootstrapController.kSystem)) {
      return;
    }

    // Prevent concurrent duplicate calls.
    if (_systemLoading) return;

    _systemLoading = true;
    notifyListeners();

    try {
      debugPrint(
          '--- [AdminProvider] START loadSystemStatus (force: $forceRefresh) ---');

      // 1. Fetch System Status Details (Uptime, Response Time, etc.)
      final statusRaw = await _cache.execute(
        key: 'system_status',
        fetcher: () => _svc.getSystemStatus(),
        forceRefresh: forceRefresh,
      );
      debugPrint('API RESPONSE (Status) => $statusRaw');

      // 2. Fetch AI Models Status (For Toggles)
      final aiModelsRaw = await _cache.execute(
        key: 'ai_models_status',
        fetcher: () => _svc.getAiModelsStatus(),
        forceRefresh: forceRefresh,
      );
      debugPrint('API RESPONSE (AI Models) => $aiModelsRaw');

      // 3. Fetch System Settings (Maintenance, Backups, etc.)
      final settingsRaw = await _cache.execute(
        key: 'system_settings',
        fetcher: () => _svc.getSystemSettings(),
        forceRefresh: forceRefresh,
      );
      debugPrint('API RESPONSE (Settings) => $settingsRaw');

      // --- PARSING PHASE ---

      // Parsing AI Models into _servicesStatus
      if (aiModelsRaw is List) {
        final Map<String, bool> parsedServices = {};
        for (final dynamic item in aiModelsRaw) {
          if (item is Map) {
            final modelName = item['model_name']?.toString() ?? '';
            final status = item['status']?.toString().toLowerCase() ?? '';
            final normalizedKey = _normalizeServiceKey(modelName);
            if (normalizedKey.isNotEmpty) {
              parsedServices[normalizedKey] = (status == 'online');
            }
          }
        }
        _servicesStatus = {..._servicesStatus, ...parsedServices};
        debugPrint('PARSED SERVICES => $_servicesStatus');
      }

      // Parsing System Settings into _systemSettings
      if (settingsRaw is List) {
        final Map<String, bool> parsedSettings = {};
        for (final dynamic item in settingsRaw) {
          if (item is SystemSetting) {
            parsedSettings[item.key] = item.isOnline;
          } else if (item is Map) {
            final key = item['key']?.toString() ?? '';
            final status = item['status']?.toString().toLowerCase() ?? '';
            if (key.isNotEmpty) {
              parsedSettings[key] = (status == 'online');
            }
          }
        }
        _systemSettings = {..._systemSettings, ...parsedSettings};
        debugPrint('PARSED SETTINGS => $_systemSettings');
      }

      // Parsing System Cards Details
      // Note: _ApiParser should be defined or replaced with appropriate parsing logic
      _statusDetails =
          SystemStatus.fromJson(Map<String, dynamic>.from(statusRaw));

      debugPrint('--- [AdminProvider] END loadSystemStatus (Success) ---');
    } catch (e, stack) {
      ProductionLogger.error(
          '[AdminProvider] loadSystemStatus CRITICAL ERROR', e);
      debugPrint('CRITICAL ERROR StackTrace: $stack');

      // Fallback: If data is null, initialize with empty but non-null maps to stop Loading Indicators
      if (_servicesStatus.isEmpty) {
        _servicesStatus = {
          'plant_disease': false,
          'animal_weight': false,
          'crop_rec': false,
          'soil_analysis': false,
          'fruit_quality': false,
          'chatbot': false,
        };
      }
      if (_systemSettings.isEmpty) {
        _systemSettings = {
          'email_notifications': false,
          'maintenance_mode': false,
          'auto_backup': false,
        };
      }
    } finally {
      _systemLoading = false;
      notifyListeners();
    }
  }

  /// Normalizes API service keys to match UI keys
  String _normalizeServiceKey(String key) {
    final k = key.toLowerCase();
    if (k.contains('plant') || k.contains('disease')) return 'plant_disease';
    if (k.contains('animal') || k.contains('weight')) return 'animal_weight';
    if (k.contains('crop') || k.contains('recommendation')) return 'crop_rec';
    if (k.contains('soil')) return 'soil_analysis';
    if (k.contains('fruit') || k.contains('quality')) return 'fruit_quality';
    if (k.contains('chatbot')) return 'chatbot';
    return key;
  }

  // ── Fixed Notification Refresh with Throttling ───────────────────────────────
  void _refreshNotificationsSafely() {
    // Simple throttling - FIXED: prevents notification spam
    final now = DateTime.now();
    if (_isRefreshing ||
        (_lastRefreshTime != null &&
            now.difference(_lastRefreshTime!) < _throttleDuration)) {
      return;
    }

    if (_notif == null || _userId.isEmpty || _userId == '0') return;

    _isRefreshing = true;
    _lastRefreshTime = now;

    // FIXED: replaced unsafe whenComplete with proper async handling
    _notif!
        .fetchNotifications(
      userId: _userId,
      showLoading: false,
      force: true,
    )
        .then((_) {
      _isRefreshing = false;
    }).catchError((e) {
      ProductionLogger.error(
          '[AdminProvider] _refreshNotificationsSafely failed', e);
      _isRefreshing = false;
    });
  }

  // ── Remaining Methods with notifyListeners Fixes ───────────────────────────────
  Future<List<AdminUser>> searchUsers(String query) async {
    try {
      return await _cache.execute(
        key: 'users_search_$query',
        fetcher: () => _svc.searchUsers(query),
        forceRefresh: true,
      );
    } catch (e) {
      ProductionLogger.error('[AdminProvider] searchUsers failed', e);
      return [];
    }
  }

  Future<bool> promoteToAdmin(String email) async {
    try {
      await _svc.promoteToAdmin(email);
      invalidateUserCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Promoted',
        body: '$email is now an Administrator.',
      );

      notifyListeners(); // FIXED: ensure UI updates
      return true;
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners(); // FIXED: ensure UI updates
      return false;
    }
  }

  Future<bool> promoteToSuperAdmin(String email) async {
    try {
      await _svc.promoteToSuperAdmin(email);
      invalidateUserCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Promoted to Super Admin',
        body: '$email is now a Super Administrator.',
      );

      notifyListeners(); // FIXED: ensure UI updates
      return true;
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners(); // FIXED: ensure UI updates
      return false;
    }
  }

  Future<bool> demoteToFarmer(String email) async {
    try {
      await _svc.demoteToFarmer(email);
      invalidateUserCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Demoted',
        body: '$email has been demoted to Farmer.',
      );

      notifyListeners(); // FIXED: ensure UI updates
      return true;
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners(); // FIXED: ensure UI updates
      return false;
    }
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      await _svc.changeUserRole(userId, newRole);
      invalidateUserCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Role Changed',
        body: 'User ($userId) role changed to $newRole.',
      );

      notifyListeners(); // FIXED: ensure UI updates
      return true;
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners(); // FIXED: ensure UI updates
      return false;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _svc.deleteUser(userId);
      invalidateUserCache();
      await loadUsers(force: true);
      notifyListeners(); // FIXED: ensure UI updates
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners(); // FIXED: ensure UI updates
      rethrow;
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      await _svc.deactivateUser(userId);
      invalidateUserCache();
      await loadUsers(force: true);
      notifyListeners(); // FIXED: ensure UI updates
    } on ApiException catch (e) {
      _usersError = e.message;
      notifyListeners(); // FIXED: ensure UI updates
      rethrow;
    }
  }

  Future<void> toggleService(String moduleName) async {
    final oldState = _servicesStatus[moduleName];
    try {
      // Don't set to null to avoid UI flickering/loading spinner
      // Just keep old state until API responds
      notifyListeners();

      final res = await _svc.toggleService(moduleName);
      final rawStatus = (res['new_status'] ?? 'updated').toString();
      final serviceName = (res['service'] ?? moduleName).toString();
      final isOnline = rawStatus.toLowerCase() == 'online';

      // Update local state immediately for responsive UI
      _servicesStatus[moduleName] = isOnline;
      notifyListeners();

      invalidateSystemCache();

      _addSystemNotification(
        title: 'Service Alert 🚜',
        body: isOnline
            ? '✅ Service ($serviceName) started successfully.'
            : '❌ Service ($serviceName) stopped successfully.',
      );

      _refreshNotificationsSafely();
    } catch (e) {
      // Revert state on error
      _servicesStatus[moduleName] = oldState;
      notifyListeners();

      ProductionLogger.error('[AdminProvider] toggleService failed', e);
      // Removed rethrow to prevent app crash and keep UI stable
    }
  }

  Future<void> toggleSystemSetting(String key) async {
    final oldState = _systemSettings[key];
    try {
      // Don't set to null to avoid UI flickering
      notifyListeners();

      await _svc.toggleSystemSetting(key);

      // Invalidate and reload to get true state from server
      invalidateSystemCache();
      await loadSystemStatus(forceRefresh: true);
    } catch (e) {
      _systemSettings[key] = oldState;
      notifyListeners();
      ProductionLogger.error('[AdminProvider] toggleSystemSetting failed', e);
    }
  }

  Future<List<UserActivity>> getUserActivity(String userId,
      {String period = 'all'}) async {
    try {
      return await _cache.execute(
        key: 'user_activity_${userId}_$period',
        fetcher: () => _svc.getUserActivity(userId, period: period),
        forceRefresh: true,
      );
    } catch (e) {
      ProductionLogger.error('[AdminProvider] getUserActivity failed', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getModelsTable() async {
    try {
      return await _cache.execute(
        key: 'models_table',
        fetcher: () => _svc.getModelsTable(),
        forceRefresh: false,
      );
    } catch (e) {
      ProductionLogger.info('[AdminProvider] getModelsTable non-critical: $e');
      return [];
    }
  }

  String getUserNameById(int id) {
    return _users
            .cast<AdminUser?>()
            .firstWhere((u) => u?.id == id.toString(), orElse: () => null)
            ?.displayName ??
        '';
  }

  String getUserEmailById(int id) {
    return _users
            .cast<AdminUser?>()
            .firstWhere((u) => u?.id == id.toString(), orElse: () => null)
            ?.email ??
        '';
  }

  void _addSystemNotification({required String title, required String body}) {
    if (_notif != null) {
      final isArabic = _locale == 'ar';
      _notif!.addSystemNotification(
        title: isArabic ? _translateArabic(title) : title,
        body: isArabic ? _translateArabic(body) : body,
      );
    }
  }

  String _translateArabic(String text) {
    final translations = {
      'User Promoted': 'تم ترقية المستخدم',
      'User Promoted to Super Admin': 'تم ترقية المستخدم إلى مشرف متميز',
      'User Demoted': 'تم تخفيض رتبة المستخدم',
      'User Role Changed': 'تم تغيير دور المستخدم',
      'is now an Administrator.': 'أصبح الآن مسؤولاً.',
      'is now a Super Administrator.': 'أصبح الآن مشرفاً متميزاً.',
      'has been demoted to Farmer.': 'تم تخفيضه إلى مزارع.',
      'role changed to': 'تم تغيير الدور إلى',
      'Service Alert 🚜': 'تنبيه الخدمات 🚜',
      'System Setting Changed': 'تغيير إعداد النظام',
      '✅ Service': '✅ خدمة',
      'started successfully.': 'تم تشغيلها بنجاح.',
      '❌ Service': '❌ خدمة',
      'stopped successfully.': 'تم إيقافها بنجاح.',
      'Setting': 'إعداد',
      'has been updated.': 'تم تحديثه.',
    };
    return translations[text] ?? text;
  }

  // ── Cache Management ───────────────────────────────────────────────────────
  void invalidateUserCache() {
    _cache.invalidate('users_summary');
  }

  void invalidateStatsCache() {
    _cache.invalidate('dashboard_stats');
  }

  void invalidateSystemCache() {
    _cache.invalidate('system_status');
    _cache.invalidate('system_settings');
  }

  void invalidateAllCache() {
    invalidateUserCache();
    invalidateStatsCache();
    invalidateSystemCache();
  }

  // ── Utility Methods ─────────────────────────────────────────────────────────
  Future<void> refreshAll() async {
    await Future.wait([
      loadStats(force: true),
      loadUsers(force: true),
      loadSystemStatus(forceRefresh: true),
    ]);
    notifyListeners();
  }

  void clearErrors() {
    if (_statsError != null || _usersError != null) {
      _statsError = null;
      _usersError = null;
      notifyListeners();
    }
  }

  void reset() {
    _userId = '0';
    _isInitialized = false;
    _isInitializing = false;
    // Clear any cached deduplicator entries so next login gets fresh data.
    RequestDeduplicator.instance.invalidate('admin_stats');
    RequestDeduplicator.instance.invalidate('admin_users');

    _stats = null;
    _statsLoading = false;
    _statsError = null;

    _users = [];
    _usersLoading = false;
    _usersError = null;

    _servicesStatus = {};
    _systemSettings = {};
    _systemLoading = false;

    _isRefreshing = false;
    _lastRefreshTime = null;

    notifyListeners();
  }

  // ── Additional Methods for Backward Compatibility ─────────────────────────────
  void logAIConfigurationUpdate() {
    _addSystemNotification(
      title: 'AI Configuration Updated',
      body: 'AI service configuration has been updated.',
    );
  }

  void updateAdminNotificationSettings({
    bool emailNotifications = true,
    bool pushNotifications = true,
    bool systemAlerts = true,
  }) {
    _addSystemNotification(
      title: 'Notification Settings Updated',
      body: 'Admin notification preferences have been saved.',
    );
  }

  Future<bool> activateUser(String userId) async {
    try {
      await _svc.activateUser(userId);
      invalidateUserCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Activated',
        body: 'User account ($userId) has been activated.',
      );

      notifyListeners();
      return true;
    } catch (e) {
      _usersError = 'Failed to activate user.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> promoteUserByEmail(String email) async {
    return await promoteToAdmin(email);
  }
}
