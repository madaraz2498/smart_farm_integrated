import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../models/report_models.dart';
import '../services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this._userId);

  String _userId;
  String get userId => _userId;

  NotificationProvider? _notifProvider;

  void updateUserId(String id) {
    if (_userId != id) {
      _userId = id;
      _stats = null;
      _reports = [];
      notifyListeners();
    }
  }

  void updateNotifProvider(NotificationProvider notif) {
    _notifProvider = notif;
  }

  final ReportsService _svc = ReportsService.instance;

  FarmerReportStats? _stats;
  List<FarmerReportItem> _reports = [];
  bool _isLoading = false;
  String? _error;

  FarmerReportStats? get stats => _stats;
  List<FarmerReportItem> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isLoading && _reports.isNotEmpty;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _svc.getStats(userId),
        _svc.listReports(userId).catchError((e) {
          debugPrint('[ReportsProvider] listReports failed: $e');
          _error = 'Failed to load report list from server: $e';
          return <FarmerReportItem>[];
        }),
      ]);
      _stats = results[0] as FarmerReportStats?;
      final list = (results[1] as List).cast<FarmerReportItem>();

      list.sort((a, b) => b.date.compareTo(a.date));
      _reports = list.take(3).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates a new report and refreshes the list — does NOT download/open.
  Future<bool> generate({String period = 'all'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _svc.generate(userId, period: period);
      await load();

      _notifProvider?.addNotification(
        title: '📊 تم إنشاء التقرير بنجاح',
        body: 'تقرير الفترة "$period" جاهز للتحميل',
        type: NotificationType.report,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Downloads the report to a local file and returns the local path.
  /// Returns null on failure and sets [error].
  Future<String?> downloadReportToFile(String reportId, {String? url}) async {
    try {
      final path = await _svc.downloadReportToFile(reportId, manualUrl: url);

      _notifProvider?.addLocalNotification(
        title: '⬇️ تم تحميل التقرير',
        body: 'تم تحميل التقرير بنجاح — اضغط لفتحه',
        type: NotificationType.report,
      );

      return path;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Opens an already-downloaded local file.
  Future<void> openLocalReport(String localPath) async {
    try {
      await _svc.openLocalFile(localPath);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}