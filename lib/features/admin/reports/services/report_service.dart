// lib/features/admin/reports/services/report_service.dart

import 'package:smart_farm/core/network/api_client.dart';
import '../models/report_model.dart';

class ReportService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<DashboardStats> getDashboardStats({String? range}) async {
    final Map<String, String>? query = range != null ? {'range': range} : null;
    final response = await _apiClient
        .get('/admin/reports/admin/reports/dashboard-stats', query: query);
    if (response is Map<String, dynamic>) {
      return DashboardStats.fromJson(response);
    }
    throw Exception('Unexpected response format for dashboard stats');
  }

  Future<Map<String, dynamic>?> generateReport() async {
    // Following the established pattern for admin report endpoints
    try {
      final response =
          await _apiClient.post('/admin/reports/admin/reports/generate-pdf');
      if (response is Map<String, dynamic>) return response;
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
