// POST /crops/recommend-crop — form-encoded (FastAPI Form fields)
class CropRecommendationRequest {
  const CropRecommendationRequest({
    required this.cityName,
    required this.soilType,
    this.userId,
    this.lang = 'ar',
  });

  final String cityName;
  final String soilType;
  final String? userId;
  final String lang;

  CropRecommendationRequest copyWith({String? userId, String? lang}) =>
      CropRecommendationRequest(
        cityName: cityName,
        soilType: soilType,
        userId: userId ?? this.userId,
        lang: lang ?? this.lang,
      );

  Map<String, String> toForm() => {
        'city_name': cityName,
        'soil': _normalizeSoilForApi(soilType),
        'lang': _normalizeLang(lang),
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

  String _normalizeLang(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'en' ? 'en' : 'ar';
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
    this.vegetables = const [],
    this.fruits = const [],
    this.fieldCrops = const [],
  });

  factory CropRecommendationResponse.fromJson(Map<String, dynamic> j) {
    // If the API returns { "recommendation": "Rice | Eggplant | ..." } as a string
    final dynamic rawRec = j['recommendation'] ?? j['result'] ?? j['data'];

    Map<String, dynamic> rec = {};
    String? rawStringRec;

    if (rawRec is Map<String, dynamic>) {
      rec = rawRec;
    } else if (rawRec is String) {
      rawStringRec = rawRec;
    } else {
      rec = j;
    }

    final daily = (j['expert_daily_guide'] ??
        j['daily_expert_guide'] ??
        j['daily_guide'] ??
        j['dailyGuides'] ??
        j['forecast']) as List?;

    // Try to find categories
    var vegetables = _extractItems(rec['vegetables'] ?? j['vegetables']);
    var fruits = _extractItems(rec['fruits'] ?? j['fruits']);
    var fieldCrops = _extractItems(rec['field_crops'] ?? j['field_crops']);

    // If all categories are empty but we have a raw string with '|', split it
    if (vegetables.isEmpty &&
        fruits.isEmpty &&
        fieldCrops.isEmpty &&
        rawStringRec != null &&
        rawStringRec.contains('|')) {
      final parts = rawStringRec
          .split('|')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        // Fallback: put them in field crops so they show up in the 3-row layout
        fieldCrops = parts;
      }
    }

    final primary = rec['primary_crop'] as String? ??
        rec['primary'] as String? ??
        rec['recommended_crop'] as String? ??
        rec['crop'] as String? ??
        (fieldCrops.isNotEmpty ? fieldCrops.first : null);

    final secondary = rec['secondary_crop'] as String? ??
        rec['secondary'] as String? ??
        (fieldCrops.length > 1 ? fieldCrops[1] : null);

    final third = rec['third_option'] as String? ??
        rec['third_crop'] as String? ??
        rec['tertiary'] as String? ??
        (fieldCrops.length > 2 ? fieldCrops[2] : null);

    final explanation = rec['explanation'] as String? ??
        rec['description'] as String? ??
        rawStringRec ??
        '';

    return CropRecommendationResponse(
      recommendedCrop: primary ?? 'Unknown',
      confidence: _d(j['confidence'] ?? rec['confidence'] ?? j['score'] ?? 0),
      explanation: explanation,
      primaryCrop: primary,
      secondaryCrop: secondary,
      thirdOption: third,
      expertAdvice: j['expert_advice'] as String? ??
          rec['expert_advice'] as String? ??
          (explanation.isNotEmpty ? explanation : null),
      generalStatus:
          j['general_status'] as String? ?? rec['general_status'] as String?,
      dailyGuide: daily == null
          ? const []
          : daily
              .whereType<Map>()
              .map((e) => CropDailyGuide.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
      yieldLevel: rec['yield_level'] as String? ?? rec['yield'] as String?,
      vegetables: vegetables,
      fruits: fruits,
      fieldCrops: fieldCrops,
    );
  }

  final String recommendedCrop, explanation;
  final double confidence;
  final String? primaryCrop;
  final String? secondaryCrop;
  final String? thirdOption;
  final String? expertAdvice;
  final String? generalStatus;
  final List<CropDailyGuide> dailyGuide;
  final String? yieldLevel;
  final List<String> vegetables;
  final List<String> fruits;
  final List<String> fieldCrops;

  String get yieldDisplay => yieldLevel ?? 'Medium';
}

List<String> _extractItems(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is Map) {
    final items = v['items'];
    if (items is List) return items.map((e) => e.toString()).toList();
  }
  if (v is String && v.isNotEmpty) return [v];
  return const [];
}

List<String> _asList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String && v.isNotEmpty) return [v];
  return const [];
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
        date: _firstGuideValue(j, const [
          'date',
          'Date',
          'day',
          'التاريخ',
        ]),
        weather: _firstGuideValue(j, const [
          'weather',
          'Weather',
          'weather_condition',
          'weatherCondition',
          'forecast',
          'الطقس',
        ]),
        irrigationAdvice: _firstGuideValue(j, const [
          'irrigation',
          'irrigation_advice',
          'irrigationAdvice',
          'Irrigation Advice',
          'water_advice',
          'waterAdvice',
          'نصيحة الري',
          'الري',
        ]),
        fertilizerAdvice: _firstGuideValue(j, const [
          'fertilizer',
          'fertilizer_advice',
          'fertilizerAdvice',
          'Fertilizer Advice',
          'fertiliser_advice',
          'fertiliserAdvice',
          'نصيحة السماد',
          'التسميد',
        ]),
        diseaseAlert: _firstGuideValue(j, const [
          'disease',
          'disease_alert',
          'diseaseAlert',
          'Disease Alert',
          'disease_warning',
          'diseaseWarning',
          'alert',
          'تنبيه الأمراض',
          'تنبيه المرض',
        ]),
      );

  final String date;
  final String weather;
  final String irrigationAdvice;
  final String fertilizerAdvice;
  final String diseaseAlert;
}

String _firstGuideValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '--';
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
