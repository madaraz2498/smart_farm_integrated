import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/request_cache.dart';
import '../../../core/utils/production_logger.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/models/notification_model.dart';

/// Dedicated provider for user management
/// Handles all user-related state and API calls
class AdminUsersProvider extends ChangeNotifier {
  AdminUsersProvider() {
    ProductionLogger.info('[AdminUsersProvider] Constructor called');
  }

  final AdminService _svc = AdminService.instance;
  final RequestCache _cache = RequestCache.instance;
  
  // State management
  List<AdminUser> _users = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // Notification provider for side effects
  NotificationProvider? _notif;
  String _locale = 'en';

  // Allow coordinator access to dependencies
  NotificationProvider? get notifProvider => _notif;
  String get locale => _locale;

  // Getters
  List<AdminUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get error => _error;
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

  /// Initialize users data - thread-safe and prevents duplicates
  Future<void> initializeIfNeeded() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    ProductionLogger.info('[AdminUsersProvider] Initializing users');
    
    try {
      await loadUsers(force: false);
      _isInitialized = true;
      ProductionLogger.info('[AdminUsersProvider] Users initialization completed');
    } catch (e) {
      ProductionLogger.error('[AdminUsersProvider] Initialization failed', e);
      _isInitialized = false; // Allow retry on failure
    } finally {
      _isInitializing = false;
    }
  }

  /// Load users data
  Future<void> loadUsers({bool force = false}) async {
    // Prevent concurrent calls
    if (_isLoading) return;
    
    // Return early if we have data and not forcing
    if (_users.isNotEmpty && !force) return;

    final wasSilent = _users.isNotEmpty;
    
    if (!wasSilent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await _cache.execute(
        key: 'users_summary',
        fetcher: () => _svc.getUsersAndSummary(),
        forceRefresh: force,
      );
      _users = data.users;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      ProductionLogger.error('[AdminUsersProvider] loadUsers failed', e);
      _error = 'Failed to load users.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search users
  Future<List<AdminUser>> searchUsers(String query) async {
    try {
      return await _cache.execute(
        key: 'users_search_$query',
        fetcher: () => _svc.searchUsers(query),
        forceRefresh: true, // Always fresh for search
      );
    } catch (e) {
      ProductionLogger.error('[AdminUsersProvider] searchUsers failed', e);
      return [];
    }
  }

  /// Promote user to admin
  Future<bool> promoteToAdmin(String email) async {
    try {
      await _svc.promoteToAdmin(email);
      invalidateCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Promoted',
        body: '$email is now an Administrator.',
      );

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Promote user to super admin
  Future<bool> promoteToSuperAdmin(String email) async {
    try {
      await _svc.promoteToSuperAdmin(email);
      invalidateCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Promoted to Super Admin',
        body: '$email is now a Super Administrator.',
      );

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Demote user to farmer
  Future<bool> demoteToFarmer(String email) async {
    try {
      await _svc.demoteToFarmer(email);
      invalidateCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Demoted',
        body: '$email has been demoted to Farmer.',
      );

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Change user role
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      await _svc.changeUserRole(userId, newRole);
      invalidateCache();
      await loadUsers(force: true);

      _addSystemNotification(
        title: 'User Role Changed',
        body: 'User ($userId) role changed to $newRole.',
      );

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _svc.deleteUser(userId);
      invalidateCache();
      await loadUsers(force: true);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  /// Deactivate user
  Future<void> deactivateUser(String userId) async {
    try {
      await _svc.deactivateUser(userId);
      invalidateCache();
      await loadUsers(force: true);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  /// Helper to get user name by ID
  String getUserNameById(int id) {
    final user = _users.where((u) => u.id == id.toString()).firstOrNull;
    return user?.displayName ?? 'Unknown';
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

  /// Simple Arabic translation for common admin actions
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
    };
    return translations[text] ?? text;
  }

  /// Clear cached users and reset initialization
  void invalidateCache() {
    _cache.invalidate('users_summary');
    _isInitialized = false;
  }

  /// Clear errors
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Reset provider state (useful for logout)
  void reset() {
    _users = [];
    _isLoading = false;
    _error = null;
    _isInitialized = false;
    _isInitializing = false;
    notifyListeners();
  }
}
