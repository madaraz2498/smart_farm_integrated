import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/soil_models.dart';

/// POST /soil/analyze-soil — form-encoded (FastAPI Form fields)
class SoilService {
  SoilService._();
  static final SoilService instance = SoilService._();
  final ApiClient _c = ApiClient.instance;

  Future<SoilAnalysisResponse> analyze(SoilAnalysisRequest req) async {
    debugPrint('[SoilService] POST /soil/analyze-soil');
    debugPrint('[SoilService] body: ${req.toJson()}');
    try {
      final data = await _c.post('/soil/analyze-soil', body: req.toJson());
      debugPrint('[SoilService] response: $data');
      return SoilAnalysisResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (e) {
      debugPrint('[SoilService] error: $e');
      throw const ApiException('Soil analysis failed.');
    }
  }
}


