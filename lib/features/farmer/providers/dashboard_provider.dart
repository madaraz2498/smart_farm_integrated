import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._userId);

  String _userId;
  String get userId => _userId;

  double? _lat;
  double? _lon;
  String _lang = 'ar';

  void updateUserId(String id) {
    if (_userId != id) {
      debugPrint('[DashboardProvider] userId updated: $_userId -> $id');
      _userId = id;
      _dashboardData = null;
      notifyListeners();

      if (id != '0' && id.isNotEmpty) {
        load();
      }
    }
  }

  void updateLocation(double? lat, double? lon) {
    if (_lat != lat || _lon != lon) {
      _lat = lat;
      _lon = lon;
      if (_userId != '0' && _userId.isNotEmpty) {
        load();
      }
    }
  }

  void updateLocale(String lang) {
    if (_lang != lang) {
      _lang = lang;
      if (_userId != '0' && _userId.isNotEmpty) {
        load();
      }
    }
  }

  final DashboardService _svc = DashboardService.instance;

  FarmerDashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  FarmerDashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    if (userId.isEmpty || userId == '0') return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboardData = await _svc.getDashboardData(
        userId,
        lat: _lat ?? 30.0444,
        lon: _lon ?? 31.2357,
        lang: _lang,
      );
      debugPrint(
          '[DashboardProvider] load success: ${_dashboardData?.weather}');
    } catch (e) {
      debugPrint('[DashboardProvider] load failed: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
