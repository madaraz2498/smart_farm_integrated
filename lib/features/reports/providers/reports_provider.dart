import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/report_models.dart';
import '../services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this.userId);

  final String         userId;
  final ReportsService _svc = ReportsService.instance;

  FarmerReportStats?     _stats;
  List<FarmerReportItem> _reports    = [];
  bool                   _loading    = false;
  bool                   _generating = false;
  String?                _error;

  FarmerReportStats?     get stats        => _stats;
  List<FarmerReportItem> get reports      => List.unmodifiable(_reports);
  bool                   get isLoading    => _loading;
  bool                   get isGenerating => _generating;
  String?                get error        => _error;

  // ── Load stats + list ─────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final results = await Future.wait([
        _svc.getStats(userId),
        _svc.listReports(userId),
      ]);
      _stats   = results[0] as FarmerReportStats;
      _reports = results[1] as List<FarmerReportItem>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load reports.';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Generate report ───────────────────────────────────────────────────────

  Future<bool> generate() async {
    _generating = true; _error = null; notifyListeners();
    try {
      await _svc.generate(userId);
      await load(); // refresh list after generation
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    } catch (_) {
      _error = 'Failed to generate report.'; return false;
    } finally {
      _generating = false; notifyListeners();
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
