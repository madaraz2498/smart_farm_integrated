// POST /crops/recommend-crop — form-encoded (FastAPI Form fields)
class CropRecommendationRequest {
  const CropRecommendationRequest({
    required this.cityName,
    required this.soilType,
    this.userId,
  });

  final String cityName;
  final String  soilType;
  final String? userId;

  CropRecommendationRequest copyWith({String? userId}) => CropRecommendationRequest(
    cityName: cityName,
    soilType: soilType,
    userId: userId ?? this.userId,
  );

  Map<String, String> toForm() => {
        'city_name': cityName,
        'soil': _normalizeSoilForApi(soilType),
        if (userId != null) 'user_id': userId!,
      };

  String _normalizeSoilForApi(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'clay':
      case 'طينية':
        return 'طينية';
      case 'sandy':
      case 'رملية':
        return 'رملية';
      case 'loamy':
      case 'silty':
      case 'طميية':
        return 'طميية';
      default:
        return 'طميية';
    }
  }
}

class CropRecommendationResponse {
  const CropRecommendationResponse({
    required this.recommendedCrop,
    required this.explanation,
    this.primaryCrop,
    this.secondaryCrop,
    this.thirdOption,
    this.expertAdvice,
    this.generalStatus,
    this.dailyGuide = const [],
    required this.confidence,
    this.yieldLevel,
  });

  factory CropRecommendationResponse.fromJson(Map<String, dynamic> j) {
    final rec = (j['recommendation'] is Map<String, dynamic>)
        ? j['recommendation'] as Map<String, dynamic>
        : j;
    final daily = (j['expert_daily_guide'] ??
            j['daily_expert_guide'] ??
            j['daily_guide'] ??
            j['dailyGuides'] ??
            j['forecast']) as List?;

    final primary = rec['primary_crop'] as String? ??
        rec['primary'] as String? ??
        rec['recommended_crop'] as String? ??
        rec['crop'] as String?;
    final secondary = rec['secondary_crop'] as String? ?? rec['secondary'] as String?;
    final third = rec['third_option'] as String? ??
        rec['third_crop'] as String? ??
        rec['tertiary'] as String?;

    return CropRecommendationResponse(
      recommendedCrop: primary ?? 'Unknown',
      confidence: _d(j['confidence'] ?? rec['confidence'] ?? j['score'] ?? 0),
      explanation: rec['explanation'] as String? ?? rec['description'] as String? ?? '',
      primaryCrop: primary,
      secondaryCrop: secondary,
      thirdOption: third,
      expertAdvice: j['expert_advice'] as String? ?? rec['expert_advice'] as String?,
      generalStatus: j['general_status'] as String? ?? rec['general_status'] as String?,
      dailyGuide: daily == null
          ? const []
          : daily
              .whereType<Map>()
              .map((e) => CropDailyGuide.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
      yieldLevel: rec['yield_level'] as String? ?? rec['yield'] as String?,
    );
  }

  final String  recommendedCrop, explanation;
  final double  confidence;
  final String? primaryCrop;
  final String? secondaryCrop;
  final String? thirdOption;
  final String? expertAdvice;
  final String? generalStatus;
  final List<CropDailyGuide> dailyGuide;
  final String? yieldLevel;

  String get yieldDisplay => yieldLevel ?? 'Medium';
}

class CropDailyGuide {
  const CropDailyGuide({
    required this.date,
    required this.weather,
    required this.irrigationAdvice,
    required this.fertilizerAdvice,
    required this.diseaseAlert,
  });

  factory CropDailyGuide.fromJson(Map<String, dynamic> j) => CropDailyGuide(
        date: j['date']?.toString() ?? j['التاريخ']?.toString() ?? '',
        weather: j['weather']?.toString() ?? j['الطقس']?.toString() ?? '',
        irrigationAdvice: j['irrigation_advice']?.toString() ?? j['نصيحة الري']?.toString() ?? '',
        fertilizerAdvice: j['fertilizer_advice']?.toString() ?? j['نصيحة السماد']?.toString() ?? '',
        diseaseAlert: j['disease_alert']?.toString() ?? j['تنبيه الأمراض']?.toString() ?? '',
      );

  final String date;
  final String weather;
  final String irrigationAdvice;
  final String fertilizerAdvice;
  final String diseaseAlert;
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int)    return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
