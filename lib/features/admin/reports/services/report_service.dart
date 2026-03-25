// lib/features/admin/reports/services/report_service.dart

import 'package:smart_farm/core/network/api_client.dart';
import '../models/report_model.dart';

class ReportService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<DashboardStats> getDashboardStats() async {
    final response =
        await _apiClient.get('/admin/reports/admin/reports/dashboard-stats');
    if (response is Map<String, dynamic>) {
      return DashboardStats.fromJson(response);
    }
    throw Exception('Unexpected response format for dashboard stats');
  }
}
