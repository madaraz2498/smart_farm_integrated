import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/fruit_models.dart';

/// POST /fruits/analyze-fruit
/// Content-Type: multipart/form-data
/// Field: "file" (image bytes)
class FruitService {
  FruitService._();
  static final FruitService instance = FruitService._();
  final ApiClient _c = ApiClient.instance;

  Future<FruitQualityResponse> analyze({
    required List<int> imageBytes,
    required String    fileName,
  }) async {
    debugPrint('[FruitService] POST /fruits/analyze-fruit  file=$fileName  size=${imageBytes.length}b');
    try {
      final data = await _c.postMultipart(
        '/fruits/analyze-fruit',
        fileField: 'file',
        fileBytes: imageBytes,
        fileName:  fileName,
      );
      debugPrint('[FruitService] response: $data');
      return FruitQualityResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (e) {
      debugPrint('[FruitService] error: $e');
      throw const ApiException('Fruit quality analysis failed.');
    }
  }
}
