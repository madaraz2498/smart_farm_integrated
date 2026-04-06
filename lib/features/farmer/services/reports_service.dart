import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/report_models.dart';

/// Farmer report endpoints:
///
///   GET  /farmer_reports/stats/{user_id}
///   GET  /farmer_reports/list/{user_id}
///   POST /farmer_reports/generate/{user_id}   (no body required)
///   GET  /reports/generate-farmer-report/{user_id}
///   GET  /reports/user-summary/{user_id}
///   GET  /farmer_reports/download/{report_id}
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
      if (data is Map<String, dynamic>) {
        // If API doesn't provide this_month, we can mock it as a fraction of total for now
        final stats = FarmerReportStats.fromJson(data);
        if (stats.thisMonth == 0 && stats.totalReports > 0) {
          return FarmerReportStats(
            totalReports: stats.totalReports,
            thisMonth:
                (stats.totalReports * 0.3).round(), // Mock 30% for this month
            growth: stats.growth,
          );
        }
        return stats;
      }
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
      debugPrint('[ReportsService] listReports error: $e');
      rethrow;
    }
  }

  // ── Generate (farmer status) ─────────────────────────────────────────────────────

  Future<String?> generate(String userId, {String period = 'all'}) async {
    final path = '/farmer_reports/generate/$userId';
    final query = {'period': period};
    debugPrint('[ReportsService] POST $path?period=$period');
    try {
      final result = await _c.post(path, query: query);
      debugPrint('[ReportsService] generate response: $result');
      if (result is Map<String, dynamic>) {
        return result['download_url'] as String? ??
            result['url'] as String? ??
            result['file_url'] as String?;
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException('Failed to generate farmer report.');
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────

  Future<void> downloadReport(String reportId, {String? manualUrl}) async {
    String? url = manualUrl;

    if (url == null) {
      if (reportId.startsWith('mock-')) {
        url =
            'https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf';
      } else {
        // Fallback to constructed URL if no manual URL provided
        url = '${ApiClient.baseUrl}/farmer_reports/download/$reportId';
      }
    }

    debugPrint('[ReportsService] Downloading PDF: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (_c.token != null && url.contains('/farmer_reports/download/'))
            'Authorization': 'Bearer ${_c.token}',
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir =
            await getTemporaryDirectory(); // Use temporary directory for better security
        final fileName =
            'report_${reportId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(bytes);
        debugPrint('[ReportsService] PDF saved to: ${file.path}');

        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          throw ApiException('Could not open PDF: ${result.message}');
        }
      } else {
        throw ApiException(
            'Failed to download PDF (Error ${response.statusCode})',
            statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[ReportsService] Download error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('An error occurred while downloading the PDF: $e');
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
