import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../models/plant_models.dart';
import '../services/plant_service.dart';

enum ScanStatus { idle, loading, result, error }

class PlantProvider extends ChangeNotifier {
  final PlantService _svc = PlantService.instance;

  ScanStatus          _status = ScanStatus.idle;
  PlantDiseaseResponse? _result;
  String?             _error;

  ScanStatus            get status => _status;
  PlantDiseaseResponse? get result => _result;
  String?               get error  => _error;
  bool get isLoading => _status == ScanStatus.loading;

  Future<void> analyze(XFile image) async {
    _status = ScanStatus.loading; _result = null; _error = null;
    notifyListeners();
    try {
      final bytes = await image.readAsBytes();
      _result = await _svc.detect(imageBytes: bytes, fileName: image.name);
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
