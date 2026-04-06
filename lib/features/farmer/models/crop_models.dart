// POST /crops/recommend-crop — form-encoded (FastAPI Form fields)
class CropRecommendationRequest {
  const CropRecommendationRequest({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.soilType,
    this.userId,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
  });

  final double temperature, humidity, rainfall;
  final String  soilType;
  final String? userId;
  final double? ph, nitrogen, phosphorus, potassium;

  CropRecommendationRequest copyWith({String? userId}) => CropRecommendationRequest(
    temperature: temperature,
    humidity: humidity,
    rainfall: rainfall,
    soilType: soilType,
    userId: userId ?? this.userId,
    ph: ph,
    nitrogen: nitrogen,
    phosphorus: phosphorus,
    potassium: potassium,
  );

  /// JSON-ready — used with ApiClient.post()
  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'humidity':    humidity,
        'rainfall':    rainfall,
        'soil_type':   soilType,
        if (userId     != null) 'user_id': int.tryParse(userId!) ?? userId!,
        if (ph         != null) 'ph': ph,
        if (nitrogen   != null) 'N':  nitrogen,
        if (phosphorus != null) 'P':  phosphorus,
        if (potassium  != null) 'K':  potassium,
      };
}

class CropRecommendationResponse {
  const CropRecommendationResponse({
    required this.recommendedCrop,
    required this.confidence,
    required this.explanation,
    this.yieldLevel,
  });

  factory CropRecommendationResponse.fromJson(Map<String, dynamic> j) =>
      CropRecommendationResponse(
        recommendedCrop: j['recommended_crop'] as String? ?? j['crop'] as String? ?? 'Unknown',
        confidence:      _d(j['confidence'] ?? j['score'] ?? 0),
        explanation:     j['explanation']  as String? ?? j['description'] as String? ?? '',
        yieldLevel:      j['yield_level']  as String? ?? j['yield'] as String?,
      );

  final String  recommendedCrop, explanation;
  final double  confidence;
  final String? yieldLevel;

  String get yieldDisplay => yieldLevel ?? 'Medium';
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int)    return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
