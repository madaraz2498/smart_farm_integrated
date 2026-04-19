import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/network/api_exception.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../models/crop_models.dart';
import '../services/crop_service.dart';

enum ScanStatus { idle, loading, result, error }

class CropProvider extends ChangeNotifier {
  CropProvider(this._userId);
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

  final CropService _svc = CropService.instance;

  ScanStatus                  _status = ScanStatus.idle;
  CropRecommendationResponse? _result;
  String?                     _error;

  ScanStatus                  get status => _status;
  CropRecommendationResponse? get result => _result;
  String?                     get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> recommend(CropRecommendationRequest req, {required String lang}) async {
    _status = ScanStatus.loading;
    _result = null;
    _error  = null;
    notifyListeners();
    try {
      _result = await _svc.recommend(req.copyWith(userId: userId, lang: lang));
      _status = ScanStatus.result;
      final isArabic = lang.toLowerCase().startsWith('ar');

      _notifProvider?.addNotification(
        title: isArabic ? '🌾 توصية المحصول جاهزة' : '🌾 Crop recommendation ready',
        body: isArabic
            ? 'المحصول الموصى به: ${_result!.recommendedCrop} — مستوى الإنتاج: ${_result!.yieldDisplay}'
            : 'Recommended crop: ${_result!.recommendedCrop} - Yield level: ${_result!.yieldDisplay}',
        type: NotificationType.report,
      );
    } on ApiException catch (e) {
      _error  = e.message;
      _status = ScanStatus.error;
    } catch (_) {
      _error  = 'Recommendation failed. Please try again.';
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