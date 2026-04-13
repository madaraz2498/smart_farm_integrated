import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/crop_models.dart';

/// POST /crops/recommend-smart-expert — form-encoded (FastAPI Form fields)
class CropService {
  CropService._();
  static final CropService instance = CropService._();
  final ApiClient _c = ApiClient.instance;

  Future<CropRecommendationResponse> recommend(CropRecommendationRequest req) async {
    debugPrint('[CropService] POST /crops/recommend-smart-expert');
    debugPrint('[CropService] body: ${req.toForm()}');
    try {
      final data = await _c.postForm('/crops/recommend-smart-expert', req.toForm());
      debugPrint('[CropService] response: $data');
      return CropRecommendationResponse.fromJson(_asMap(data));
    } on ApiException { rethrow; }
    catch (e) {
      debugPrint('[CropService] error: $e');
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


