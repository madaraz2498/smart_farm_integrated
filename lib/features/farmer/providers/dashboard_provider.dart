import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import '../../../core/utils/production_logger.dart';
import '../../../core/utils/cache_manager.dart';

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
  bool _hasLoadedOnce = false;
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

      // Only trigger a load if data hasn't been loaded yet.
      if (!_hasLoadedOnce && lat != null && lon != null &&
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
      // Only schedule a fresh load if we haven't loaded yet.
      // After first load, locale changes are picked up on next explicit refresh.
      if (!_hasLoadedOnce && _userId != '0' && _userId.isNotEmpty) {
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
    final cached = await CacheManager.instance.getCachedDashboard(userId);
    if (cached != null) {
      _dashboardData = FarmerDashboardData.fromJson(cached);
      ProductionLogger.dashboard('serving cached dashboard while fetching fresh data');
      notifyListeners();
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
      ProductionLogger.dashboard('API loading started');
      _dashboardData = await _svc.getDashboardData(
        userId,
        lat: lat,
        lon: lon,
        lang: _lang,
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

    // Reset the "loaded once" guard so _fetchFreshData actually runs.
    _hasLoadedOnce = false;
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
