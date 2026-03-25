// lib/features/admin/reports/providers/report_provider.dart

import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class AdminReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  DashboardStats? _stats;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  String _selectedRange = 'last_7_days';
  String? _lastGeneratedUrl;
  DateTime? _lastGeneratedTime;

  DashboardStats? get stats => _stats;
  List<ServiceUsage> get usageList => _stats?.usageByService ?? [];
  List<UserGrowth> get growthList => _stats?.userGrowth ?? [];
  List<DailyActivity> get activityList => _stats?.dailyActivity ?? [];
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  String get selectedRange => _selectedRange;
  String? get lastGeneratedUrl => _lastGeneratedUrl;
  DateTime? get lastGeneratedTime => _lastGeneratedTime;

  void setRange(String range) {
    _selectedRange = range;
    fetchAllReports();
  }

  Future<void> fetchAllReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _service.getDashboardStats(range: _selectedRange);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateNewReport() async {
    _isGenerating = true;
    notifyListeners();
    try {
      final response = await _service.generateReport();
      if (response != null && response['file_url'] != null) {
        _lastGeneratedUrl = response['file_url'] as String;
        _lastGeneratedTime = DateTime.now();
        notifyListeners();
        return _lastGeneratedUrl;
      }
      return null;
    } catch (e) {
      // Do not set global _error to avoid breaking main UI
      debugPrint('[AdminReportProvider] generate error: $e');
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
