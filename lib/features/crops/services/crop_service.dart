import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/crop_models.dart';

/// POST /crops/recommend-crop — form-encoded (FastAPI Form fields)
class CropService {
  CropService._();
  static final CropService instance = CropService._();
  final ApiClient _c = ApiClient.instance;

  Future<CropRecommendationResponse> recommend(CropRecommendationRequest req) async {
    debugPrint('[CropService] POST /crops/recommend-crop');
    debugPrint('[CropService] body: ${req.toJson()}');
    try {
      final data = await _c.post('/crops/recommend-crop', body: req.toJson());
      debugPrint('[CropService] response: $data');
      return CropRecommendationResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (e) {
      debugPrint('[CropService] error: $e');
      throw const ApiException('Crop recommendation failed.');
    }
  }
}
