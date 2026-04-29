import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import '../../../core/utils/production_logger.dart';
import '../../../core/utils/cache_manager.dart';
import '../../../core/utils/app_lifecycle_manager.dart'; // AppBootstrapController, PageLifecycleManager, RequestDeduplicator

/// Dashboard data provider.
///
/// FIXES applied vs original:
/// - Removed the [AppLifecycleManager.addOnResumeCallback] registration.
///   Resume-triggered full reloads caused cascading API spam every time the
///   user returned to the app. The [AppLifecycleManager] now enforces a
///   30-second gap globally, but for the dashboard the correct behaviour is
///   to only reload on explicit pull-to-refresh.
/// - [updateLocation] / [updateLocale] no longer schedule a reload when data
///   has already been loaded once; they just store the new values so the next
///   explicit [refresh] can use them.
/// - [_isFetchingData] guard prevents concurrent duplicate API calls.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._userId);

  String _userId;
  String get userId => _userId;

  double? _lat;
  double? _lon;
  String _lang = 'ar';

  Timer? _debounceTimer;
  // Set to true by FarmerWelcomePage.initState and false on dispose so that
  // location updates arriving before the page opens don't trigger API calls.
  bool _pageIsActive = false;
  bool _hasLoadedOnce = false;

  /// Call from FarmerWelcomePage.initState (via addPostFrameCallback).
  void markPageActive() {
    _pageIsActive = true;

    // Register page with lifecycle manager.
    PageLifecycleManager.instance.onPageEnter(PageLifecycleManager.kFarmerDashboard);

    // Unlock the dashboard module so data loading is permitted.
    AppBootstrapController.instance.unlockDashboard();

    // If coordinates already arrived, kick off the load now.
    if (!_hasLoadedOnce && _lat != null && _lon != null &&
        _userId != '0' && _userId.isNotEmpty) {
      _scheduleLoad();
    }
  }

  /// Call from FarmerWelcomePage.dispose.
  void markPageInactive() {
    _pageIsActive = false;
    PageLifecycleManager.instance.onPageExit(PageLifecycleManager.kFarmerDashboard);
  }
  bool _isWaitingForLocation = false;
  bool _isRefreshing = false;
  bool _isFetchingData = false;
  DateTime? _lastSuccessfulLoad;

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

  // ── Dependency updates from ProxyProvider ────────────────────────────────

  void updateUserId(String id) {
    if (_userId != id) {
      ProductionLogger.dashboard('userId updated: $_userId -> $id');
      _userId = id;
      _dashboardData = null;
      _hasLoadedOnce = false;
      _lastSuccessfulLoad = null;
      notifyListeners();
      // Do NOT auto-schedule a load here. The dashboard page (FarmerWelcomePage)
      // drives the first load via updateLocation once GPS coordinates arrive.
      // Auto-fetching from updateUserId causes an API storm at app startup when
      // ProxyProvider fires multiple rapid updates (userId, location, locale).
    }
  }

  void updateLocation(double? lat, double? lon) {
    if (_lat != lat || _lon != lon) {
      _lat = lat;
      _lon = lon;
      ProductionLogger.dashboard('location updated: lat=$lat, lon=$lon');

      // Only trigger a load when the dashboard page is actually open AND
      // data hasn't been loaded yet. This prevents startup API spam from
      // background GPS updates before the user sees the dashboard.
      if (_pageIsActive && !_hasLoadedOnce && lat != null && lon != null &&
          _userId != '0' && _userId.isNotEmpty) {
        if (_isWaitingForLocation) {
          _isWaitingForLocation = false;
          _loadOnce();
        } else {
          _scheduleLoad();
        }
      }
      // If already loaded, the new coordinates will be used on next refresh().
    }
  }

  void updateLocale(String lang) {
    if (_lang != lang) {
      _lang = lang;
      // Only schedule a fresh load if the page is active and not yet loaded.
      // The _pageIsActive guard ensures no API call fires before the dashboard
      // screen is visible. After first load, locale changes apply on next refresh.
      if (_pageIsActive && !_hasLoadedOnce && _userId != '0' && _userId.isNotEmpty) {
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
      ProductionLogger.dashboard('already loaded once, skipping duplicate call');
      return;
    }
    load();
  }

  // ── Data fetching ─────────────────────────────────────────────────────────

  Future<void> load() async {
    if (userId.isEmpty || userId == '0') return;
    if (_hasLoadedOnce) {
      ProductionLogger.dashboard('already loaded once, skipping');
      return;
    }

    _isLoading = true;
    _error = null;

    // Show cached data immediately while fetching fresh data.
    // Wrapped in try-catch: old/corrupt cache entries (e.g. the previous
    // toJson format that stored 'weather' as a String instead of a Map)
    // must not crash the app — we simply discard them and wait for the API.
    final cached = await CacheManager.instance.getCachedDashboard(userId);
    if (cached != null) {
      try {
        _dashboardData = FarmerDashboardData.fromJson(cached);
        ProductionLogger.dashboard('serving cached dashboard while fetching fresh data');
        notifyListeners();
      } catch (e) {
        ProductionLogger.error('Cached dashboard is corrupt or outdated, discarding: $e');
        await CacheManager.instance.clearUserCache(userId);
      }
    }

    try {
      await _fetchFreshData();
    } catch (e) {
      ProductionLogger.error('load failed: $e');
      _error = e.toString();
    } finally {
      if (!_isWaitingForLocation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchFreshData() async {
    if (_isFetchingData) {
      ProductionLogger.dashboard('API call already in progress, skipping');
      return;
    }

    final lat = _lat;
    final lon = _lon;

    if (lat == null || lon == null) {
      ProductionLogger.dashboard('waiting for coordinates...');
      _isWaitingForLocation = true;
      notifyListeners();
      return;
    }

    _isWaitingForLocation = false;
    _isFetchingData = true;
    notifyListeners();

    try {
      // ── Bootstrap gate check ────────────────────────────────────────────
      if (!AppBootstrapController.instance
          .isModuleUnlocked(AppBootstrapController.kDashboard)) {
        ProductionLogger.dashboard('Dashboard module not yet unlocked — aborting fetch');
        _isFetchingData = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      ProductionLogger.dashboard('API loading started');

      // ── RequestDeduplicator: merges concurrent calls into ONE request ───
      final cacheKey = 'dashboard_\${userId}_\${lat}_\${lon}_\$_lang';
      _dashboardData = await RequestDeduplicator.instance.execute(
        key: cacheKey,
        fetcher: () => _svc.getDashboardData(userId, lat: lat, lon: lon, lang: _lang),
      );

      _hasLoadedOnce = true;
      _lastSuccessfulLoad = DateTime.now();

      if (_dashboardData != null) {
        await CacheManager.instance
            .cacheDashboard(userId, _dashboardData!.toJson());
      }

      ProductionLogger.dashboard(
          'load success: weather=${_dashboardData?.weather}');
    } catch (e) {
      ProductionLogger.error('fetch fresh data failed: $e');
      rethrow;
    } finally {
      _isFetchingData = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh — always fetches fresh data.
  Future<void> refresh() async {
    if (!canRefresh) return;

    if (_lat == null || _lon == null) {
      ProductionLogger.dashboard('refresh: no coordinates available');
      return;
    }

    // Reset the "loaded once" guard and deduplicator cache so _fetchFreshData
    // actually performs a fresh network request.
    _hasLoadedOnce = false;
    RequestDeduplicator.instance.invalidate(
        'dashboard_\${userId}_\${_lat}_\${_lon}_\$_lang');
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