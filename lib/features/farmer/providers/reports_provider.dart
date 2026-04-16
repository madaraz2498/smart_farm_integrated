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

  Future<bool> generate({String period = 'all'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = await _svc.generate(userId, period: period);
      await load();
      if (url != null) {
        await _svc.downloadReport('latest', manualUrl: url);
      }

      _notifProvider?.addNotification(
        title: '📊 تم إنشاء التقرير بنجاح',
        body: 'تقرير الفترة "$period" جاهز للتحميل',
        type: NotificationType.report,
      );

      if (userId.isNotEmpty && userId != '0') {
        unawaited(_notifProvider?.fetchNotifications(userId) ?? Future.value());
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> downloadReport(String reportId, {String? url}) async {
    try {
      await _svc.downloadReport(reportId, manualUrl: url);

      _notifProvider?.addLocalNotification(
        title: '⬇️ تم تحميل التقرير',
        body: 'تم تحميل التقرير بنجاح على جهازك',
        type: NotificationType.report,
      );
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
