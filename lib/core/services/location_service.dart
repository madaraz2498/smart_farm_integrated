import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  static const String _kCityKey = 'user_city';
  static const String _kLatKey = 'user_lat';
  static const String _kLonKey = 'user_lon';

  // ── Session-level in-memory cache ─────────────────────────────────────────
  // Once GPS succeeds in this app session, we never call Geolocator again
  // unless clearSessionCache() is explicitly called (manual refresh only).
  Map<String, dynamic>? _sessionCache;

  // In-flight deduplication: if a GPS request is already running, subsequent
  // callers await the same Future instead of spawning a new concurrent GPS call.
  Future<Map<String, dynamic>?>? _inFlight;

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    // Return session cache immediately — no GPS hardware call needed.
    if (_sessionCache != null) {
      ProductionLogger.location('returning session-cached location');
      return _sessionCache;
    }

    // If a request is already in-flight, wait for it instead of spawning a
    // second concurrent GPS call (the root cause of "already loading" loops).
    if (_inFlight != null) {
      ProductionLogger.location('GPS already in-flight, awaiting existing request...');
      return _inFlight;
    }

    _inFlight = _fetchFromGPS();
    try {
      final result = await _inFlight!;
      _sessionCache = result; // cache on success
      return result;
    } finally {
      _inFlight = null;
    }
  }

  Future<Map<String, dynamic>?> _fetchFromGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 20),
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      ProductionLogger.location('[LocationService] Position => lat=${position.latitude}, lon=${position.longitude}, accuracy=${position.accuracy}');

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,);

      String city = 'Unknown';
      if (placemarks.isNotEmpty) {
        city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? 'Unknown';
      }
      ProductionLogger.location('Resolved city => $city');

      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCityKey, city);
      await prefs.setDouble(_kLatKey, position.latitude);
      await prefs.setDouble(_kLonKey, position.longitude);

      return {
        'city': city,
        'lat': position.latitude,
        'lon': position.longitude,
      };
    } catch (e) {
      ProductionLogger.location('Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStoredLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_kCityKey);
    final lat = prefs.getDouble(_kLatKey);
    final lon = prefs.getDouble(_kLonKey);

    if (city != null && lat != null && lon != null) {
      return {'city': city, 'lat': lat, 'lon': lon};
    }
    return null;
  }

  /// Store location data in SharedPreferences
  Future<void> storeLocation(Map<String, dynamic> location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCityKey, location['city'] ?? 'Unknown');
      await prefs.setDouble(_kLatKey, location['lat']?.toDouble() ?? 0.0);
      await prefs.setDouble(_kLonKey, location['lon']?.toDouble() ?? 0.0);
      ProductionLogger.location('Location stored: \${location["city"]}, \${location["lat"]}, \${location["lon"]}');
    } catch (e) {
      ProductionLogger.location('Error storing location: $e');
    }
  }

  /// Clears the in-memory session cache so the next [getCurrentLocation] call
  /// triggers a real GPS request. Only used by [LocationProvider.refreshLocation].
  void clearSessionCache() {
    _sessionCache = null;
    ProductionLogger.location('session cache cleared for manual refresh');
  }
}
