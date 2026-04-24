import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../models/scan_status.dart';
import '../../../core/utils/production_logger.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../models/animal_models.dart';
import '../services/animal_service.dart';

class AnimalProvider extends ChangeNotifier {
  AnimalProvider(this._userId);
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

  final AnimalService _svc = AnimalService.instance;

  ScanStatus            _status = ScanStatus.idle;
  AnimalWeightResponse? _result;
  String?               _error;

  ScanStatus            get status => _status;
  AnimalWeightResponse? get result => _result;
  String?               get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> estimate(XFile image, {required String lang}) async {
    _status = ScanStatus.loading;
    _result = null;
    _error = null;
    notifyListeners();
    try {
      final bytes = await image.readAsBytes();
      _result = await _svc.estimateWeight(
        imageBytes: bytes,
        fileName:   image.name,
        userId:     userId,
        lang:       lang,
      );
      _status = ScanStatus.result;
      final isArabic = lang.toLowerCase().startsWith('ar');

      _notifProvider?.addLocalNotification(
        title: isArabic
            ? '🐄 تحليل وزن الحيوان اكتمل'
            : '🐄 Animal weight analysis completed',
        body: isArabic
            ? 'النوع: ${_result!.animalType} — الوزن المقدر: ${_result!.weightDisplay} (دقة: ${(_result!.confidence * 100).toStringAsFixed(0)}%)'
            : 'Type: ${_result!.animalType} - Estimated weight: ${_result!.weightDisplay} (confidence: ${(_result!.confidence * 100).toStringAsFixed(0)}%)',
        type: NotificationType.report,
      );
    } on ApiException catch (e) {
      _error  = e.message;
      _status = ScanStatus.error;
    } catch (e) {
      ProductionLogger.error('Animal estimate failed', e);
      _error  = 'Estimation failed. Please try again.';
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