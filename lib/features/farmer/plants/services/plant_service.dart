import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_exception.dart';
import '../models/plant_models.dart';

/// POST /plants/detect
/// Content-Type: multipart/form-data
/// Field: "file" (image bytes)
class PlantService {
  PlantService._();
  static final PlantService instance = PlantService._();
  final ApiClient _c = ApiClient.instance;

  Future<PlantDiseaseResponse> detect({
    required List<int> imageBytes,
    required String    fileName,
    required String    userId,
  }) async {
    debugPrint('[PlantService] POST /plants/detect  file=$fileName  userId=$userId');
    try {
      final data = await _c.postMultipart(
        '/plants/detect',
        fileField: 'file',
        fileBytes: imageBytes,
        fileName:  fileName,
        fields:    {'user_id': userId},
      );
      debugPrint('[PlantService] response: $data');
      return PlantDiseaseResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (e) {
      debugPrint('[PlantService] error: $e');
      throw const ApiException('Plant disease analysis failed.');
    }
  }
}


