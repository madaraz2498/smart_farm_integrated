import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/request_cache.dart';
import '../../../core/utils/production_logger.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

/// Dedicated provider for dashboard statistics
/// Handles all stats-related state and API calls
class AdminStatsProvider extends ChangeNotifier {
  AdminStatsProvider() {
    ProductionLogger.info('[AdminStatsProvider] Constructor called');
  }

  final AdminService _svc = AdminService.instance;
  final RequestCache _cache = RequestCache.instance;
  
  // State management
  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Getters
  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Initialize stats data - thread-safe and prevents duplicates
  Future<void> initializeIfNeeded() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    ProductionLogger.info('[AdminStatsProvider] Initializing stats');
    
    try {
      await loadStats(force: false);
      _isInitialized = true;
      ProductionLogger.info('[AdminStatsProvider] Stats initialization completed');
    } catch (e) {
      ProductionLogger.error('[AdminStatsProvider] Initialization failed', e);
      _isInitialized = false; // Allow retry on failure
    } finally {
      _isInitializing = false;
    }
  }

  /// Load dashboard statistics
  Future<void> loadStats({bool force = false}) async {
    // Prevent concurrent calls
    if (_isLoading) return;
    
    // Return early if we have data and not forcing
    if (_stats != null && !force) return;

    final wasSilent = _stats != null;
    
    if (!wasSilent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _stats = await _cache.execute(
        key: 'dashboard_stats',
        fetcher: () => _svc.getDashboardStats(),
        forceRefresh: force,
      );
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      ProductionLogger.error('[AdminStatsProvider] loadStats failed', e);
      _error = 'Failed to load statistics.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh stats data
  Future<void> refresh() async {
    await loadStats(force: true);
  }

  /// Clear cached stats and reset initialization
  void invalidateCache() {
    _cache.invalidate('dashboard_stats');
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
    _stats = null;
    _isLoading = false;
    _error = null;
    _isInitialized = false;
    _isInitializing = false;
    notifyListeners();
  }
}
