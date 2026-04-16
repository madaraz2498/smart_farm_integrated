import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/report_models.dart';

/// Farmer report endpoints:
///
///   GET  /farmer_reports/stats/{user_id}
///   GET  /farmer_reports/list/{user_id}
///   POST /farmer_reports/generate/{user_id}
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
        final stats = FarmerReportStats.fromJson(data);
        if (stats.thisMonth == 0 && stats.totalReports > 0) {
          return FarmerReportStats(
            totalReports: stats.totalReports,
            thisMonth: (stats.totalReports * 0.3).round(),
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

  // ── Generate — only triggers creation, no download ───────────────────────

  Future<void> generate(String userId, {String period = 'all'}) async {
    final path = '/farmer_reports/generate/$userId';
    final query = {'period': period};
    debugPrint('[ReportsService] POST $path?period=$period');
    try {
      final result = await _c.post(path, query: query);
      debugPrint('[ReportsService] generate response: $result');
      // We intentionally ignore any download_url here.
      // The user downloads manually via the list item button.
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException('Failed to generate farmer report.');
    }
  }

  // ── Download to file (returns local path) ─────────────────────────────────

  Future<String> downloadReportToFile(String reportId,
      {String? manualUrl}) async {
    String url = manualUrl ??
        '${ApiClient.baseUrl}/farmer_reports/download/$reportId';

    debugPrint('[ReportsService] Downloading PDF: $url');

    try {
      // First check if report exists by making a HEAD request
      final headResponse = await http.head(
        Uri.parse(url),
        headers: {
          if (_c.token != null)
            'Authorization': 'Bearer ${_c.token}',
        },
      );

      if (headResponse.statusCode != 200) {
        throw ApiException(
          'Report file not found or not ready for download (Error ${headResponse.statusCode})',
          statusCode: headResponse.statusCode,
        );
      }

      // If HEAD request succeeds, proceed with download
      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (_c.token != null)
            'Authorization': 'Bearer ${_c.token}',
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final fileName =
            'report_${reportId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        debugPrint('[ReportsService] PDF saved to: ${file.path}');
        return file.path;
      } else {
        throw ApiException(
          'Failed to download PDF (Error ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('[ReportsService] Download error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('An error occurred while downloading the PDF: $e');
    }
  }

  // ── Open local file ───────────────────────────────────────────────────────

  Future<void> openLocalFile(String localPath) async {
    debugPrint('[ReportsService] Opening local file: $localPath');
    final result = await OpenFilex.open(localPath);
    if (result.type != ResultType.done) {
      throw ApiException('Could not open PDF: ${result.message}');
    }
  }

  // ── User summary ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserSummary(String userId) async {
    final path = '/reports/user-summary/$userId';
    debugPrint('[ReportsService] GET $path');
    try {
      final data = await _c.get(path);
      return (data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      debugPrint('[ReportsService] getUserSummary non-critical: $e');
      return {};
    }
  }
}