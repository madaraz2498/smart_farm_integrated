import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/animal_models.dart';

/// POST /animals/estimate-weight
/// Content-Type: multipart/form-data
/// Field: "file" (image bytes)
class AnimalService {
  AnimalService._();
  static final AnimalService instance = AnimalService._();
  final ApiClient _c = ApiClient.instance;

  Future<AnimalWeightResponse> estimateWeight({
    required List<int> imageBytes,
    required String    fileName,
  }) async {
    debugPrint('[AnimalService] POST /animals/estimate-weight  file=$fileName  size=${imageBytes.length}b');
    try {
      final data = await _c.postMultipart(
        '/animals/estimate-weight',
        fileField: 'file',
        fileBytes: imageBytes,
        fileName:  fileName,
      );
      debugPrint('[AnimalService] response: $data');
      return AnimalWeightResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (e) {
      debugPrint('[AnimalService] error: $e');
      throw const ApiException('Animal weight estimation failed.');
    }
  }
}
