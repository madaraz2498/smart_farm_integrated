import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_exception.dart';
import '../models/report_models.dart';

/// Farmer report endpoints:
///
///   GET  /farmer_reports/stats/{user_id}
///   GET  /farmer_reports/list/{user_id}
///   POST /farmer_reports/generate/{user_id}   (no body required)
///   GET  /reports/generate-farmer-report/{user_id}
///   GET  /reports/user-summary/{user_id}
class ReportsService {
  ReportsService._();
  static final ReportsService instance = ReportsService._();
  final ApiClient _c = ApiClient.instance;

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<FarmerReportStats> getStats(String userId) async {
    final path = '/farmer_reports/stats/$userId';
    debugPrint('[ReportsService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[ReportsService] getStats response: $data');
      if (data is Map<String, dynamic>) return FarmerReportStats.fromJson(data);
      return const FarmerReportStats(
          totalReports: 0, thisMonth: 0, growth: '+0%');
    } catch (e) {
      debugPrint('[ReportsService] getStats non-critical: $e');
      return const FarmerReportStats(
          totalReports: 0, thisMonth: 0, growth: '+0%');
    }
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Future<List<FarmerReportItem>> listReports(String userId) async {
    final path = '/farmer_reports/list/$userId';
    debugPrint('[ReportsService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[ReportsService] listReports response: $data');
      if (data is List) {
        return data
            .map((e) => FarmerReportItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Some APIs wrap in { "reports": [...] }
      if (data is Map && data['reports'] is List) {
        return (data['reports'] as List)
            .map((e) => FarmerReportItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ReportsService] listReports non-critical: $e');
      return [];
    }
  }

  // ── Generate (farmer) ─────────────────────────────────────────────────────

  Future<void> generate(String userId) async {
    final path = '/farmer_reports/generate/$userId';
    debugPrint('[ReportsService] POST $path');
    try {
      final result = await _c.post(path);
      debugPrint('[ReportsService] generate response: $result');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException('Failed to generate report.');
    }
  }

  // ── Full farmer report ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateFarmerReport(String userId) async {
    final path = '/reports/generate-farmer-report/$userId';
    debugPrint('[ReportsService] POST $path');
    try {
      final data = await _c.post(path);
      debugPrint('[ReportsService] generateFarmerReport response: $data');
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      debugPrint('[ReportsService] generateFarmerReport non-critical: $e');
      return {};
    }
  }

  // ── User summary ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserSummary(String userId) async {
    final path = '/reports/user-summary/$userId';
    debugPrint('[ReportsService] GET $path');
    try {
      final data = await _c.get(path);
      debugPrint('[ReportsService] getUserSummary response: $data');
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      debugPrint('[ReportsService] getUserSummary non-critical: $e');
      return {};
    }
  }
}


