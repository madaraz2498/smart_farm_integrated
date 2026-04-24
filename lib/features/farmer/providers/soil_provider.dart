import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/scan_status.dart';
import '../../../core/utils/production_logger.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../models/soil_models.dart';
import '../services/soil_service.dart';

class SoilProvider extends ChangeNotifier {
  SoilProvider(this._userId);
  String _userId;
  String get userId => _userId;

  NotificationProvider? _notifProvider;

  void updateUserId(String id) {
    if (_userId != id) {
      _userId = id;
      reset();
    }
  }

  void updateNotifProvider(NotificationProvider notif) {
    _notifProvider = notif;
  }

  final SoilService _svc = SoilService.instance;

  ScanStatus            _status = ScanStatus.idle;
  SoilAnalysisResponse? _result;
  String?               _error;

  ScanStatus            get status => _status;
  SoilAnalysisResponse? get result => _result;
  String?               get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> analyze(SoilAnalysisRequest req, {required String lang}) async {
    _status = ScanStatus.loading;
    _result = null;
    _error  = null;
    notifyListeners();
    try {
      _result = await _svc.analyze(req.copyWith(userId: userId, lang: lang));
      _status = ScanStatus.result;
      final isArabic = lang.toLowerCase().startsWith('ar');

      _notifProvider?.addLocalNotification(
        title: isArabic ? '🌱 نتائج تحليل التربة' : '🌱 Soil analysis results',
        body: isArabic
            ? 'نوع التربة: ${_result!.soilType} — مستوى الخصوبة: ${_result!.fertilityLevel}'
            : 'Soil type: ${_result!.soilType} - Fertility level: ${_result!.fertilityLevel}',
        type: NotificationType.report,
      );
    } on ApiException catch (e) {
      _error  = e.message;
      _status = ScanStatus.error;
    } catch (e) {
      ProductionLogger.error('Soil analysis failed', e);
      _error  = 'Analysis failed. Please try again.';
      _status = ScanStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = ScanStatus.idle;
    _result = null;
    _error  = null;
    notifyListeners();
  }
}