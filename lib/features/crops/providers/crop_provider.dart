import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/crop_models.dart';
import '../services/crop_service.dart';

enum ScanStatus { idle, loading, result, error }

class CropProvider extends ChangeNotifier {
  final CropService _svc = CropService.instance;

  ScanStatus                _status = ScanStatus.idle;
  CropRecommendationResponse? _result;
  String?                   _error;

  ScanStatus                  get status => _status;
  CropRecommendationResponse? get result => _result;
  String?                     get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> recommend(CropRecommendationRequest req) async {
    _status = ScanStatus.loading; _result = null; _error = null;
    notifyListeners();
    try {
      _result = await _svc.recommend(req); _status = ScanStatus.result;
    } on ApiException catch (e) {
      _error  = e.message; _status = ScanStatus.error;
    } catch (_) {
      _error  = 'Recommendation failed. Please try again.'; _status = ScanStatus.error;
    }
    notifyListeners();
  }

  void reset() { _status = ScanStatus.idle; _result = null; _error = null; notifyListeners(); }
}
