import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../models/fruit_models.dart';
import '../services/fruit_service.dart';

enum ScanStatus { idle, loading, result, error }

class FruitProvider extends ChangeNotifier {
  FruitProvider(this._userId);
  String _userId;
  String get userId => _userId;

  void updateUserId(String id) {
    if (_userId != id) {
      _userId = id;
      reset();
    }
  }

  final FruitService _svc = FruitService.instance;

  ScanStatus _status = ScanStatus.idle;
  FruitQualityResponse? _result;
  String? _error;

  ScanStatus get status => _status;
  FruitQualityResponse? get result => _result;
  String? get error => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> analyze(XFile image) async {
    _status = ScanStatus.loading;
    _result = null;
    _error = null;
    notifyListeners();
    try {
      final bytes = await image.readAsBytes();
      _result = await _svc.analyze(
        imageBytes: bytes,
        fileName: image.name,
        userId: userId,
      );
      _status = ScanStatus.result;
    } on ApiException catch (e) {
      _error = e.message;
      _status = ScanStatus.error;
    } catch (_) {
      _error = 'Analysis failed. Please try again.';
      _status = ScanStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = ScanStatus.idle;
    _result = null;
    _error = null;
    notifyListeners();
  }
}
