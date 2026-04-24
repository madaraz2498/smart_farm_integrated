import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../models/scan_status.dart';
import '../../../core/utils/production_logger.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../models/plant_models.dart';
import '../services/plant_service.dart';

class PlantProvider extends ChangeNotifier {
  PlantProvider(this._userId);
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

  final PlantService _svc = PlantService.instance;

  ScanStatus            _status = ScanStatus.idle;
  PlantDiseaseResponse? _result;
  String?               _error;

  ScanStatus            get status => _status;
  PlantDiseaseResponse? get result => _result;
  String?               get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> analyze(XFile image, {required String lang}) async {
    _status = ScanStatus.loading;
    _result = null;
    _error  = null;
    notifyListeners();
    try {
      final bytes = await image.readAsBytes();
      _result = await _svc.detect(
        imageBytes: bytes,
        fileName:   image.name,
        userId:     userId,
        lang:       lang,
      );
      _status = ScanStatus.result;
      final isArabic = lang.toLowerCase().startsWith('ar');

      final isHealthy = _result!.isHealthy;
      _notifProvider?.addLocalNotification(
        title: isArabic
            ? (isHealthy ? '🌿 النبات بصحة جيدة' : '⚠️ تم اكتشاف مرض في النبات')
            : (isHealthy ? '🌿 Plant looks healthy' : '⚠️ Plant disease detected'),
        body: isArabic
            ? (isHealthy
                ? 'النبات يبدو سليماً — لا يوجد مرض مكتشف (دقة: ${_result!.confidencePct})'
                : 'المرض: ${_result!.prediction} — دقة التشخيص: ${_result!.confidencePct}')
            : (isHealthy
                ? 'The plant appears healthy - No disease detected (confidence: ${_result!.confidencePct})'
                : 'Disease: ${_result!.prediction} - Confidence: ${_result!.confidencePct}'),
        type: isHealthy ? NotificationType.report : NotificationType.system,
      );
    } on ApiException catch (e) {
      _error  = e.message;
      _status = ScanStatus.error;
    } catch (e) {
      ProductionLogger.error('Plant analysis failed', e);
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