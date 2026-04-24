import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/soil_models.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

/// POST /soil/analyze-soil — form-encoded (FastAPI Form fields)
class SoilService {
  SoilService._();
  static final SoilService instance = SoilService._();
  final ApiClient _c = ApiClient.instance;

  Future<SoilAnalysisResponse> analyze(SoilAnalysisRequest req) async {
    ProductionLogger.info('POST /soil/analyze-soil');
    ProductionLogger.info('body: ${req.toForm()}');
    try {
      final data = await _c.postForm('/soil/analyze-soil', req.toForm());
      ProductionLogger.info('response: $data');
      return SoilAnalysisResponse.fromJson(_asMap(data));
    } on ApiException { rethrow; }
    catch (e) {
      ProductionLogger.info('error: $e');
      throw const ApiException('Soil analysis failed.');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['result'] ?? data['analysis'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw const ApiException('Invalid soil response format.');
  }
}


