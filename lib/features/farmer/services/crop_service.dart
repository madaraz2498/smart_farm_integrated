import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/crop_models.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

/// POST /crops/recommend-smart-expert — form-encoded (FastAPI Form fields)
class CropService {
  CropService._();
  static final CropService instance = CropService._();
  final ApiClient _c = ApiClient.instance;

  Future<CropRecommendationResponse> recommend(CropRecommendationRequest req) async {
    ProductionLogger.info('POST /crops/recommend-smart-expert');
    ProductionLogger.info('body: ${req.toForm()}');
    try {
      final data = await _c.postForm('/crops/recommend-smart-expert', req.toForm());
      ProductionLogger.info('response: $data');
      return CropRecommendationResponse.fromJson(_asMap(data));
    } on ApiException { rethrow; }
    catch (e) {
      ProductionLogger.info('error: $e');
      throw const ApiException('Crop recommendation failed.');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['result'] ?? data['prediction'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw const ApiException('Invalid crop response format.');
  }
}


