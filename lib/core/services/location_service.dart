import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  static const String _kCityKey = 'user_city';
  static const String _kLatKey = 'user_lat';
  static const String _kLonKey = 'user_lon';

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
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
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = 'Unknown';
      if (placemarks.isNotEmpty) {
        city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? 'Unknown';
      }

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
      debugPrint('[LocationService] Error: $e');
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
}
