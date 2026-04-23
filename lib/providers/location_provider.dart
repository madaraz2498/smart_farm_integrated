import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/location_service.dart';
import '../core/utils/production_logger.dart';

/// Manages device location for the app session.
///
/// KEY INVARIANT: GPS hardware is accessed at most ONCE per session.
/// - On cold start we load the persisted location immediately, then
///   request a fresh GPS fix in the background (only once).
/// - Subsequent calls to [requestLocation] are no-ops unless [force] is true.
/// - [refreshLocation] clears the service-level session cache and re-fetches.
class LocationProvider extends ChangeNotifier {
  LocationProvider() {
    _init();
  }

  final LocationService _svc = LocationService.instance;

  String? _city;
  double? _lat;
  double? _lon;
  bool _isLoading = false;
  // True once a GPS request (successful or not) has completed this session.
  bool _fetchedThisSession = false;

  String? get city => _city;
  double? get lat => _lat;
  double? get lon => _lon;
  bool get isLoading => _isLoading;
  bool get hasLocation => _city != null && _lat != null && _lon != null;

  // ── Initialise: load persisted location, then start background GPS fix ────

  Future<void> _init() async {
    // 1. Load whatever was stored from last session — immediate, no GPS used.
    final stored = await _svc.getStoredLocation();
    if (stored != null) {
      _city = stored['city'];
      _lat = stored['lat'];
      _lon = stored['lon'];
      ProductionLogger.location('loaded cached location: $_city, $_lat, $_lon');
      notifyListeners();
    }

    // 2. Fire a single background GPS refresh so location stays up-to-date.
    //    We do NOT await this — callers already have the cached value above.
    _fetchOnce();
  }

  // ── Single background fetch (runs at most once per session) ───────────────

  Future<void> _fetchOnce() async {
    if (_fetchedThisSession || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      ProductionLogger.location('requesting GPS (once per session)...');
      final loc = await _svc.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          ProductionLogger.location('GPS timeout — keeping cached location');
          return null;
        },
      );

      if (loc != null) {
        _city = loc['city'];
        _lat = loc['lat'];
        _lon = loc['lon'];
        ProductionLogger.location('GPS ready: $_city ($_lat, $_lon)');
        await _svc.storeLocation(loc);
      } else if (!hasLocation) {
        // No GPS and no cache — apply fallback so the app is never stuck.
        final fallback = _fallback();
        _city = fallback['city'];
        _lat = fallback['lat'];
        _lon = fallback['lon'];
        ProductionLogger.location('GPS unavailable, using fallback: $_city');
      } else {
        ProductionLogger.location('GPS unavailable, keeping cached: $_city');
      }
    } catch (e) {
      ProductionLogger.error('GPS fetch error: $e');
      if (!hasLocation) {
        final fallback = _fallback();
        _city = fallback['city'];
        _lat = fallback['lat'];
        _lon = fallback['lon'];
      }
    } finally {
      _isLoading = false;
      _fetchedThisSession = true;
      notifyListeners();
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called by [AuthWrapper] and [FarmerWelcomePage].
  /// If GPS has already been fetched (or is in progress) this session,
  /// this is a cheap no-op — guaranteeing zero duplicate GPS calls.
  Future<void> requestLocation({bool force = false}) async {
    if (!force && _fetchedThisSession) {
      ProductionLogger.location('requestLocation: already fetched this session, skipping');
      return;
    }
    if (!force && _isLoading) {
      ProductionLogger.location('requestLocation: fetch in progress, skipping');
      return;
    }
    if (force) {
      _svc.clearSessionCache();
      _fetchedThisSession = false;
    }
    await _fetchOnce();
  }

  /// Backward-compatible alias kept for [FarmerWelcomePage].
  Future<void> requestLocationForDashboard() => requestLocation();

  /// Manual pull-to-refresh: clears the session cache and re-fetches GPS.
  Future<void> refreshLocation() async {
    _svc.clearSessionCache();
    _fetchedThisSession = false;
    await _fetchOnce();
  }

  Map<String, dynamic> _fallback() => {
        'city': 'Cairo',
        'lat': 30.0444,
        'lon': 31.2357,
      };
}
