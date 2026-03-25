// lib/features/admin/reports/providers/report_provider.dart

import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class AdminReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  List<ServiceUsage> get usageList => _stats?.usageByService ?? [];
  List<UserGrowth> get growthList => _stats?.userGrowth ?? [];
  List<DailyActivity> get activityList => _stats?.dailyActivity ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _service.getDashboardStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
