import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/location_service.dart';
import '../core/utils/production_logger.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider() {
    _init();
  }

  final LocationService _svc = LocationService.instance;

  String? _city;
  double? _lat;
  double? _lon;
  bool _isLoading = false;
  bool _hasRequestedOnce = false;
  bool _isWaitingForFreshGps = false;
  Completer<Map<String, dynamic>?>? _locationCompleter;

  String? get city => _city;
  double? get lat => _lat;
  double? get lon => _lon;
  bool get isLoading => _isLoading;
  bool get hasLocation => _city != null && _lat != null && _lon != null;
  bool get isWaitingForFreshGps => _isWaitingForFreshGps;

  Future<void> _init() async {
    final stored = await _svc.getStoredLocation();
    if (stored != null) {
      _city = stored['city'];
      _lat = stored['lat'];
      _lon = stored['lon'];
      ProductionLogger.location('loaded cached location: $_city, $_lat, $_lon');
      notifyListeners();
    }
  }

  /// Requests location permission and updates coordinates.
  /// On startup, waits for fresh GPS unless permission denied or timeout.
  Future<void> requestLocation({bool force = true, bool waitForFreshGps = true}) async {
    // Prevent duplicate requests
    if (_isLoading) {
      ProductionLogger.location('already loading, waiting...');
      if (_locationCompleter != null) {
        await _locationCompleter!.future;
      }
      return;
    }

    // If we have cached location and not forcing fresh GPS, use cache immediately
    if (!force && hasLocation && !waitForFreshGps) {
      ProductionLogger.location('using cached location');
      return;
    }

    // If we have cached location but should wait for fresh GPS
    if (!force && hasLocation && waitForFreshGps && !_hasRequestedOnce) {
      ProductionLogger.location('waiting fresh GPS...');
      _isWaitingForFreshGps = true;
      notifyListeners();
    }

    _isLoading = true;
    _locationCompleter = Completer<Map<String, dynamic>?>();
    notifyListeners();

    try {
      ProductionLogger.location('requesting fresh GPS...');
      
      // Add 5-second timeout for GPS request
      final loc = await _svc.getCurrentLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          ProductionLogger.location('GPS timeout after 5 seconds');
          return null; // Return null to indicate GPS timeout
        },
      );
      
      if (loc != null) {
        // Fresh GPS received - update and cache
        _city = loc['city'];
        _lat = loc['lat'];
        _lon = loc['lon'];
        ProductionLogger.location('fresh GPS loaded: $_lat, $_lon');
        
        // Update cache with fresh GPS data
        await _svc.storeLocation(loc);
        ProductionLogger.location('cache updated with fresh GPS');
      } else {
        // GPS failed or timed out
        if (hasLocation) {
          ProductionLogger.location('GPS failed, using cached location');
        } else {
          ProductionLogger.location('GPS failed, using fallback location');
          final fallback = _getFallbackLocation();
          if (fallback != null) {
            _city = fallback['city'];
            _lat = fallback['lat'];
            _lon = fallback['lon'];
          }
        }
      }
      
      _locationCompleter!.complete(loc);
    } catch (e) {
      ProductionLogger.error('GPS request failed: $e');
      final fallback = _getFallbackLocation();
      if (fallback != null) {
        _city = fallback['city'];
        _lat = fallback['lat'];
        _lon = fallback['lon'];
        ProductionLogger.location('using fallback location: $_city, $_lat, $_lon');
      }
      _locationCompleter!.complete(fallback);
    } finally {
      _isLoading = false;
      _hasRequestedOnce = true;
      _isWaitingForFreshGps = false;
      _locationCompleter = null;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _getFallbackLocation() {
    // Cairo fallback coordinates
    return {
      'city': 'Cairo',
      'lat': 30.0444,
      'lon': 31.2357,
    };
  }

  /// Force refresh location (for manual refresh)
  Future<void> refreshLocation() async {
    _hasRequestedOnce = false;
    await requestLocation(force: true, waitForFreshGps: false);
  }

  /// Request location specifically for dashboard loading
  /// Waits for fresh GPS on startup, uses cache for subsequent calls
  Future<void> requestLocationForDashboard() async {
    if (_hasRequestedOnce) {
      // Already requested once, use cache if available
      if (hasLocation) {
        ProductionLogger.location('dashboard using cached location');
        return;
      }
    }
    
    // First time - wait for fresh GPS
    await requestLocation(force: false, waitForFreshGps: true);
  }
}
