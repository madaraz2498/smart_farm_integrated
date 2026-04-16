import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/animal_models.dart';

/// POST /animals/estimate-weight
/// Content-Type: multipart/form-data
/// Field: "image" (image bytes)
class AnimalService {
  AnimalService._();
  static final AnimalService instance = AnimalService._();
  final ApiClient _c = ApiClient.instance;

  Future<AnimalWeightResponse> estimateWeight({
    required List<int> imageBytes,
    required String fileName,
    required String userId,
    required String lang,
  }) async {
    debugPrint(
        '[AnimalService] POST /animals/estimate-weight  file=$fileName  userId=$userId');
    try {
      final data = await _c.postMultipart(
        '/animals/estimate-weight',
        fileField: 'image',
        fileBytes: imageBytes,
        fileName: fileName,
        fields: {
          'user_id': userId,
          'lang': _normalizeLang(lang),
        },
      );
      debugPrint('[AnimalService] response: $data');
      return AnimalWeightResponse.fromJson(_asMap(data));
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[AnimalService] error: $e');
      throw const ApiException('Animal weight estimation failed.');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['result'] ?? data['prediction'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw const ApiException('Invalid animal response format.');
  }

  String _normalizeLang(String lang) {
    final value = lang.trim().toLowerCase();
    return value == 'en' ? 'en' : 'ar';
  }
}
