import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/plant_models.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

/// POST /plants/detect
/// Content-Type: multipart/form-data
/// Field: "image" (image bytes)
class PlantService {
  PlantService._();
  static final PlantService instance = PlantService._();
  final ApiClient _c = ApiClient.instance;

  Future<PlantDiseaseResponse> detect({
    required List<int> imageBytes,
    required String fileName,
    required String userId,
    required String lang,
  }) async {
    ProductionLogger.info('[PlantService] POST /plants/detect  file=$fileName  userId=$userId');
    try {
      final data = await _c.postMultipart(
        '/plants/detect',
        fileField: 'image',
        fileBytes: imageBytes,
        fileName: fileName,
        fields: {
          'user_id': userId,
          'lang': _normalizeLang(lang),
        },);
      ProductionLogger.info('response: $data');
      return PlantDiseaseResponse.fromJson(_asMap(data));
    } on ApiException {
      rethrow;
    } catch (e) {
      ProductionLogger.info('error: $e');
      throw const ApiException('Plant disease analysis failed.');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['result'] ?? data['prediction'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw const ApiException('Invalid plant response format.');
  }

  String _normalizeLang(String lang) {
    final value = lang.trim().toLowerCase();
    return value == 'en' ? 'en' : 'ar';
  }
}
