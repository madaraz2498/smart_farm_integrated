import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/soil_models.dart';
import '../services/soil_service.dart';

enum ScanStatus { idle, loading, result, error }

class SoilProvider extends ChangeNotifier {
  SoilProvider(this._userId);
  String _userId;
  String get userId => _userId;

  void updateUserId(String id) {
    if (_userId != id) {
      _userId = id;
      reset();
    }
  }

  final SoilService _svc = SoilService.instance;

  ScanStatus          _status = ScanStatus.idle;
  SoilAnalysisResponse? _result;
  String?             _error;

  ScanStatus            get status => _status;
  SoilAnalysisResponse? get result => _result;
  String?               get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> analyze(SoilAnalysisRequest req) async {
    _status = ScanStatus.loading; _result = null; _error = null;
    notifyListeners();
    try {
      _result = await _svc.analyze(req.copyWith(userId: userId));
      _status = ScanStatus.result;
    } on ApiException catch (e) {
      _error  = e.message; _status = ScanStatus.error;
    } catch (_) {
      _error  = 'Analysis failed. Please try again.'; _status = ScanStatus.error;
    }
    notifyListeners();
  }

  void reset() { _status = ScanStatus.idle; _result = null; _error = null; notifyListeners(); }
}
