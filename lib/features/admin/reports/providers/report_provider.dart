// lib/features/admin/reports/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class AdminReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  DashboardStats? _stats;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  String _selectedRange = 'last_7_days';
  final List<Map<String, dynamic>> _generatedReports = [];

  DashboardStats? get stats => _stats;
  List<ServiceUsage> get usageList => _stats?.usageByService ?? [];
  List<UserGrowth> get growthList => _stats?.userGrowth ?? [];
  List<DailyActivity> get activityList => _stats?.dailyActivity ?? [];
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  String get selectedRange => _selectedRange;
  List<Map<String, dynamic>> get generatedReports =>
      List.unmodifiable(_generatedReports);

  bool _hasFetchedOnce = false;

  void setRange(String range) {
    _selectedRange = range;
    // Range changed — always re-fetch.
    _hasFetchedOnce = false;
    fetchAllReports();
  }

  Future<void> fetchAllReports({bool force = false}) async {
    // Skip if already in-flight.
    if (_isLoading) return;
    // Skip if already loaded and no force signal.
    if (_hasFetchedOnce && !force) return;

    final isSilent = _stats != null;

    if (!isSilent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _stats = await _service.getDashboardStats(range: _selectedRange);
      _hasFetchedOnce = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateNewReport(NotificationProvider notif) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final response = await _service.generateReport();
      if (response != null && response['file_url'] != null) {
        final newReport = {
          'url': response['file_url'] as String,
          'time': DateTime.now(),
        };
        // Add to the beginning of the list to show newest first
        _generatedReports.insert(0, newReport);

        // Add notification
        notif.addSystemNotification(
          title: 'Report Ready',
          body: 'Your admin report has been generated successfully.',
        );

        notifyListeners();
        return newReport['url'] as String;
      }
      return null;
    } catch (e) {
      // Do not set global _error to avoid breaking main UI
      ProductionLogger.reports('generate error: $e');
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
