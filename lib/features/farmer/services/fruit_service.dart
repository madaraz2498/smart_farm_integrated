import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/fruit_models.dart';

/// POST /fruits/analyze-fruit
/// Content-Type: multipart/form-data
/// Field: "image" (image bytes)
class FruitService {
  FruitService._();
  static final FruitService instance = FruitService._();
  final ApiClient _c = ApiClient.instance;

  Future<FruitQualityResponse> analyze({
    required List<int> imageBytes,
    required String fileName,
    required String userId,
    required String lang,
  }) async {
    debugPrint(
        '[FruitService] POST /fruits/analyze-fruit  file=$fileName  userId=$userId');
    try {
      final data = await _c.postMultipart(
        '/fruits/analyze-fruit',
        fileField: 'image',
        fileBytes: imageBytes,
        fileName: fileName,
        fields: {
          'user_id': userId,
          'lang': _normalizeLang(lang),
        },
      );
      debugPrint('[FruitService] response: $data');
      return FruitQualityResponse.fromJson(_asMap(data));
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[FruitService] error: $e');
      throw const ApiException('Fruit quality analysis failed.');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['result'] ?? data['prediction'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw const ApiException('Invalid fruit response format.');
  }

  String _normalizeLang(String lang) {
    final value = lang.trim().toLowerCase();
    return value == 'en' ? 'en' : 'ar';
  }
}
