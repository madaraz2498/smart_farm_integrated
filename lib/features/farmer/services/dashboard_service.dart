import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  DashboardService._();
  static final instance = DashboardService._();
  final ApiClient _c = ApiClient.instance;

  // ── Farmer Dashboard All Data ─────────────────────────────────────────────

  Future<FarmerDashboardData> getDashboardData(String userId,
      {double lat = 30.0444, double lon = 31.2357, String lang = 'ar'}) async {
    final path = '/farmer/dashboard-all/$userId';
    final query = {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'lang': lang,
    };
    debugPrint('[DashboardService] GET $path with query $query');
    try {
      final data = await _c.get(path, query: query);
      debugPrint('[DashboardService] getDashboardData response: $data');
      if (data is Map<String, dynamic>) {
        return FarmerDashboardData.fromJson(data);
      }
      throw const ApiException('Invalid dashboard data received');
    } catch (e) {
      debugPrint('[DashboardService] getDashboardData error: $e');
      rethrow;
    }
  }
}
