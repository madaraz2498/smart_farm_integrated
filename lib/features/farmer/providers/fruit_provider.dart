import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../models/fruit_models.dart';
import '../services/fruit_service.dart';

enum ScanStatus { idle, loading, result, error }

class FruitProvider extends ChangeNotifier {
  FruitProvider(this._userId);
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

  final FruitService _svc = FruitService.instance;

  ScanStatus            _status = ScanStatus.idle;
  FruitQualityResponse? _result;
  String?               _error;

  ScanStatus            get status => _status;
  FruitQualityResponse? get result => _result;
  String?               get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> analyze(XFile image, {required String lang}) async {
    _status = ScanStatus.loading;
    _result = null;
    _error  = null;
    notifyListeners();
    try {
      final bytes = await image.readAsBytes();
      _result = await _svc.analyze(
        imageBytes: bytes,
        fileName:   image.name,
        userId:     userId,
        lang:       lang,
      );
      _status = ScanStatus.result;
      final isArabic = lang.toLowerCase().startsWith('ar');

      final grade = _result!.grade.toUpperCase();
      final emoji = grade == 'A' ? '🍎' : grade == 'B' ? '🟡' : '🔴';
      _notifProvider?.addLocalNotification(
        title: isArabic
            ? '$emoji تحليل جودة الفاكهة اكتمل'
            : '$emoji Fruit quality analysis completed',
        body: isArabic
            ? 'الدرجة: $grade — النضج: ${_result!.ripeness} — ${_result!.gradeLabel}'
            : 'Grade: $grade - Ripeness: ${_result!.ripeness} - ${_result!.gradeLabel}',
        type: NotificationType.report,
      );
    } on ApiException catch (e) {
      _error  = e.message;
      _status = ScanStatus.error;
    } catch (_) {
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