import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/request_cache.dart';
import '../../../core/utils/production_logger.dart';
import '../services/admin_service.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/models/notification_model.dart';

/// Dedicated provider for system settings and services
/// Handles all system-related state and API calls
class AdminSystemProvider extends ChangeNotifier {
  AdminSystemProvider() {
    ProductionLogger.info('[AdminSystemProvider] Constructor called');
  }

  final AdminService _svc = AdminService.instance;
  final RequestCache _cache = RequestCache.instance;
  
  // State management
  Map<String, bool> _servicesStatus = {};
  Map<String, bool> _systemSettings = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // Notification provider for side effects
  NotificationProvider? _notif;
  String _locale = 'en';

  // Allow coordinator access to dependencies
  NotificationProvider? get notifProvider => _notif;
  String get locale => _locale;
  
  // Thread-safe notification refresh
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  // Getters
  Map<String, bool> get servicesStatus => Map.unmodifiable(_servicesStatus);
  Map<String, bool> get systemSettings => Map.unmodifiable(_systemSettings);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Update dependencies (called from ProxyProvider)
  void updateNotif(NotificationProvider? notif) {
    if (_notif == notif) return;
    _notif = notif;
  }

  void updateLocale(String languageCode) {
    if (_locale == languageCode) return;
    _locale = languageCode;
  }

  /// Initialize system data - thread-safe and prevents duplicates
  Future<void> initializeIfNeeded() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    ProductionLogger.info('[AdminSystemProvider] Initializing system');
    
    try {
      await loadSystemStatus(forceRefresh: false);
      _isInitialized = true;
      ProductionLogger.info('[AdminSystemProvider] System initialization completed');
    } catch (e) {
      ProductionLogger.error('[AdminSystemProvider] Initialization failed', e);
      _isInitialized = false; // Allow retry on failure
    } finally {
      _isInitializing = false;
    }
  }

  /// Load system status and settings
  Future<void> loadSystemStatus({bool forceRefresh = false}) async {
    // Prevent concurrent calls
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Use cache for system status
      final status = await _cache.execute(
        key: 'system_status',
        fetcher: () => _svc.getSystemStatus(),
        forceRefresh: forceRefresh,
      );

      // Use cache for system settings
      final settingsList = await _cache.execute(
        key: 'system_settings',
        fetcher: () => _svc.getSystemSettings(),
        forceRefresh: forceRefresh,
      );

      // Process services status
      if (status['services'] is Map) {
        _servicesStatus = Map<String, bool>.from(status['services']);
      }

      // Convert List<SystemSetting> to Map<String, bool>
      final settingsMap = <String, bool>{};
      for (final setting in settingsList) {
        settingsMap[setting.key] = setting.isOnline;
      }
      _systemSettings = settingsMap;
      
    } catch (e) {
      ProductionLogger.info('[AdminSystemProvider] loadSystemStatus error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle service status
  Future<void> toggleService(String moduleName) async {
    try {
      final res = await _svc.toggleService(moduleName);
      final rawStatus = (res['new_status'] ?? 'updated').toString();
      final serviceName = (res['service'] ?? moduleName).toString();
      final isOnline = rawStatus.toLowerCase() == 'online';

      ProductionLogger.info('[AdminSystemProvider] Toggled $moduleName -> $rawStatus');

      // Update local state immediately for responsive UI
      _servicesStatus[moduleName] = isOnline;
      notifyListeners();

      // Invalidate cache to force refresh on next load
      invalidateCache();
      
      // Add notification
      _addSystemNotification(
        title: 'Service Alert 🚜',
        body: isOnline
            ? '✅ Service ($serviceName) started successfully.'
            : '❌ Service ($serviceName) stopped successfully.',
      );

      // Refresh notifications safely
      await _refreshNotificationsSafely();
      
    } catch (e) {
      // Revert state on error
      _servicesStatus[moduleName] = _servicesStatus[moduleName] ?? false;
      notifyListeners();
      
      ProductionLogger.error('[AdminSystemProvider] toggleService failed', e);
      rethrow;
    }
  }

  /// Toggle system setting
  Future<void> toggleSystemSetting(String settingName) async {
    try {
      await _svc.toggleSystemSetting(settingName);

      ProductionLogger.info('[AdminSystemProvider] Toggled setting: $settingName');

      // Update local state immediately for responsive UI
      final currentValue = _systemSettings[settingName] ?? false;
      _systemSettings[settingName] = !currentValue;
      notifyListeners();

      // Invalidate cache to force refresh on next load
      invalidateCache();

      // Add notification
      _addSystemNotification(
        title: 'System Setting Changed',
        body: 'Setting ($settingName) has been updated.',
      );

      // Refresh notifications safely
      await _refreshNotificationsSafely();
      
    } catch (e) {
      // Revert state on error
      final currentValue = _systemSettings[settingName] ?? false;
      _systemSettings[settingName] = currentValue;
      notifyListeners();
      
      ProductionLogger.error('[AdminSystemProvider] toggleSystemSetting failed', e);
      rethrow;
    }
  }

  /// Thread-safe notification refresh
  Future<void> _refreshNotificationsSafely() async {
    if (_isRefreshing) {
      // If refresh is already in progress, wait for it to complete
      _refreshCompleter?.complete();
      _refreshCompleter = Completer<void>();
      return _refreshCompleter!.future;
    }

    if (_notif == null) return;

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      await _notif!.fetchNotifications(
        userId: '0', // System notifications don't need user ID
        showLoading: false,
        force: true,
      );
    } catch (e) {
      ProductionLogger.error('[AdminSystemProvider] _refreshNotificationsSafely failed', e);
    } finally {
      _isRefreshing = false;
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  /// Get models table data
  Future<List<Map<String, dynamic>>> getModelsTable() async {
    try {
      return await _cache.execute(
        key: 'models_table',
        fetcher: () => _svc.getModelsTable(),
        forceRefresh: false,
      );
    } catch (e) {
      ProductionLogger.info('[AdminSystemProvider] getModelsTable non-critical: $e');
      return [];
    }
  }

  /// Add system notification (side effect)
  void _addSystemNotification({required String title, required String body}) {
    if (_notif != null) {
      final isArabic = _locale == 'ar';
      _notif!.addSystemNotification(
        title: isArabic ? _translateArabic(title) : title,
        body: isArabic ? _translateArabic(body) : body,
      );
    }
  }

  /// Simple Arabic translation for common system actions
  String _translateArabic(String text) {
    final translations = {
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

  /// Clear cached system data and reset initialization
  void invalidateCache() {
    _cache.invalidate('system_status');
    _cache.invalidate('system_settings');
    _isInitialized = false;
  }

  /// Clear errors
  void clearError() {
    // System provider doesn't track errors, but method exists for consistency
  }

  /// Reset provider state (useful for logout)
  void reset() {
    _servicesStatus = {};
    _systemSettings = {};
    _isLoading = false;
    _isInitialized = false;
    _isInitializing = false;
    _isRefreshing = false;
    _refreshCompleter = null;
    notifyListeners();
  }
}
