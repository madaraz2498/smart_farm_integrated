import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import '../../../core/utils/production_logger.dart';
import '../../../core/utils/cache_manager.dart';
import '../../../core/utils/app_lifecycle_manager.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._userId) {
    _initializeLifecycle();
  }

  String _userId;
  String get userId => _userId;

  double? _lat;
  double? _lon;
  String _lang = 'ar';
  
  Timer? _debounceTimer;
  bool _hasLoadedOnce = false;
  bool _isWaitingForLocation = false;
  bool _isRefreshing = false;
  bool _isFetchingData = false; // Prevent duplicate API calls
  DateTime? _lastSuccessfulLoad;

  void _initializeLifecycle() {
    AppLifecycleManager.instance.addOnResumeCallback(() {
      if (_hasLoadedOnce && _userId.isNotEmpty && _userId != '0') {
        ProductionLogger.info('App resumed, refreshing dashboard');
        refresh();
      }
    });
  }

  void updateUserId(String id) {
    if (_userId != id) {
      ProductionLogger.dashboard('userId updated: $_userId -> $id');
      _userId = id;
      _dashboardData = null;
      _hasLoadedOnce = false;
      _lastSuccessfulLoad = null;
      notifyListeners();

      if (id != '0' && id.isNotEmpty) {
        _scheduleLoad();
      }
    }
  }

  void updateLocation(double? lat, double? lon) {
    if (_lat != lat || _lon != lon) {
      _lat = lat;
      _lon = lon;
      ProductionLogger.dashboard('location updated: lat=$lat, lon=$lon');
      
      // If we were waiting for location and now have it, load immediately
      if (_isWaitingForLocation && lat != null && lon != null) {
        ProductionLogger.dashboard('coordinates available, retrying dashboard load');
        _isWaitingForLocation = false;
        _loadOnce();
      } else if (_userId != '0' && _userId.isNotEmpty && !_hasLoadedOnce) {
        // First time loading with coordinates
        _scheduleLoad();
      }
    }
  }

  void updateLocale(String lang) {
    if (_lang != lang) {
      _lang = lang;
      if (_userId != '0' && _userId.isNotEmpty) {
        _scheduleLoad();
      }
    }
  }

  void _scheduleLoad() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isLoading && !_hasLoadedOnce) {
        _loadOnce();
      }
    });
  }

  void _loadOnce() {
    if (_hasLoadedOnce) {
      debugPrint('[DashboardProvider] already loaded, skipping duplicate call');
      return;
    }
    load();
  }

  final DashboardService _svc = DashboardService.instance;

  FarmerDashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  FarmerDashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isWaitingForLocation => _isWaitingForLocation;
  String? get error => _error;
  bool get canRefresh => !_isLoading && _userId.isNotEmpty && _userId != '0';
  DateTime? get lastSuccessfulLoad => _lastSuccessfulLoad;

  Future<void> load() async {
    if (userId.isEmpty || userId == '0') return;

    if (_hasLoadedOnce) {
      ProductionLogger.dashboard('already loaded once, skipping');
      return;
    }

    _isLoading = true;
    _error = null;
    _isWaitingForLocation = true;
    notifyListeners();
    
    try {
      // On startup, wait for fresh location before loading dashboard
      if (!_hasLoadedOnce) {
        ProductionLogger.dashboard('loading with fresh location');
        
        // Try to fetch fresh data - will wait for coordinates if needed
        await _fetchFreshData();
        
        // If we're still waiting for coordinates, don't mark as loaded
        if (_isWaitingForLocation) {
          return; // Keep loading state active
        }
      } else {
        // Subsequent loads can use cache first
        final cached = await CacheManager.instance.getCachedDashboard(userId);
        if (cached != null) {
          _dashboardData = FarmerDashboardData.fromJson(cached);
          ProductionLogger.dashboard('fallback using cache');
          notifyListeners();
          
          // Still fetch fresh data in background
          _fetchFreshData();
          return;
        }

        await _fetchFreshData();
      }
    } catch (e) {
      ProductionLogger.error('load failed: $e');
      _error = e.toString();
    } finally {
      // Only stop loading if we're not waiting for coordinates
      if (!_isWaitingForLocation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchFreshData() async {
    // Prevent duplicate API calls
    if (_isFetchingData) {
      ProductionLogger.dashboard('API call already in progress, skipping');
      return;
    }
    
    // Check coordinates before making API call
    final lat = _lat;
    final lon = _lon;
    
    if (lat == null || lon == null) {
      ProductionLogger.dashboard('waiting coordinates...');
      _isWaitingForLocation = true;
      notifyListeners();
      return;
    }
    
    // We have coordinates, clear waiting state
    _isWaitingForLocation = false;
    
    ProductionLogger.dashboard('coordinates ready');
    ProductionLogger.dashboard('API loading started');
    
    _isFetchingData = true;
    notifyListeners();
    
    try {
      _dashboardData = await _svc.getDashboardData(
        userId,
        lat: lat,
        lon: lon,
        lang: _lang,
      );
      
      _hasLoadedOnce = true;
      _lastSuccessfulLoad = DateTime.now();
      
      // Cache the fresh data
      if (_dashboardData != null) {
        await CacheManager.instance.cacheDashboard(userId, _dashboardData!.toJson());
      }
      
      ProductionLogger.dashboard('load success: weather=${_dashboardData?.weather}');
    } catch (e) {
      ProductionLogger.error('fetch fresh data failed: $e');
      rethrow;
    } finally {
      _isFetchingData = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard data (for pull-to-refresh)
  Future<void> refresh() async {
    if (!canRefresh) return;
    
    // Check if we have coordinates before refreshing
    if (_lat == null || _lon == null) {
      ProductionLogger.dashboard('refresh: no coordinates available');
      return;
    }
    
    _isRefreshing = true;
    _error = null;
    notifyListeners();
    
    try {
      await _fetchFreshData();
      ProductionLogger.dashboard('refresh success');
    } catch (e) {
      ProductionLogger.error('refresh failed: $e');
      _error = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
