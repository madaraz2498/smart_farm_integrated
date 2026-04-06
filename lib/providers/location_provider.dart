import 'package:flutter/foundation.dart';
import '../core/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider() {
    _init();
  }

  final LocationService _svc = LocationService.instance;

  String? _city;
  double? _lat;
  double? _lon;
  bool _isLoading = false;

  String? get city => _city;
  double? get lat => _lat;
  double? get lon => _lon;
  bool get isLoading => _isLoading;
  bool get hasLocation => _city != null && _lat != null && _lon != null;

  Future<void> _init() async {
    final stored = await _svc.getStoredLocation();
    if (stored != null) {
      _city = stored['city'];
      _lat = stored['lat'];
      _lon = stored['lon'];
      notifyListeners();
    }
  }

  /// Requests location permission and updates coordinates.
  /// If [force] is true, it will always request from GPS.
  /// If [force] is false, it will only request if no location is stored.
  Future<void> requestLocation({bool force = true}) async {
    if (!force && hasLocation) return;

    _isLoading = true;
    notifyListeners();

    try {
      final loc = await _svc.getCurrentLocation();
      if (loc != null) {
        _city = loc['city'];
        _lat = loc['lat'];
        _lon = loc['lon'];
      }
    } catch (e) {
      debugPrint('[LocationProvider] requestLocation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
