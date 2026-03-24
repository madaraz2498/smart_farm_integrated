import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/report_models.dart';
import '../services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this._userId);

  String _userId;
  String get userId => _userId;

  void updateUserId(String id) {
    if (_userId != id) {
      _userId = id;
      _stats = null;
      _reports = [];
      notifyListeners();
    }
  }

  final ReportsService _svc = ReportsService.instance;

  FarmerReportStats?  _stats;
  List<FarmerReportItem> _reports   = [];
  bool         _isLoading = false;
  String?      _error;

  FarmerReportStats?  get stats     => _stats;
  List<FarmerReportItem> get reports   => _reports;
  bool         get isLoading => _isLoading;
  bool         get isGenerating => _isLoading && _reports.isNotEmpty; 
  String?      get error     => _error;

  Future<void> load() async {
    _isLoading = true; _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _svc.getStats(userId),
        _svc.listReports(userId),
      ]);
      _stats = results[0] as FarmerReportStats?;
      _reports = (results[1] as List).cast<FarmerReportItem>();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generate() async {
    _isLoading = true; notifyListeners();
    try {
      await _svc.generate(userId);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Full farmer report (detailed) ─────────────────────────────────────────

  Future<Map<String, dynamic>> generateFarmerReport() async {
    try {
      return await _svc.generateFarmerReport(userId);
    } catch (_) { return {}; }
  }

  void clearError() { _error = null; notifyListeners(); }
}
