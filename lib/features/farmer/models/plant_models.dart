// POST /plants/detect — multipart field: "file"
class PlantDiseaseResponse {
  const PlantDiseaseResponse({
    required this.prediction,
    required this.condition,
    required this.confidence,
    required this.isHealthy,
    this.cropType,
    this.description,
    this.treatment,
  });

  factory PlantDiseaseResponse.fromJson(Map<String, dynamic> j) {
    final payload = (j['analysis'] is Map<String, dynamic>)
        ? j['analysis'] as Map<String, dynamic>
        : j;

    final prediction = payload['prediction'] as String? ??
        payload['disease'] as String? ??
        payload['disease_ar'] as String? ??
        payload['disease_en'] as String? ??
        payload['full_diagnosis_en'] as String? ??
        payload['class'] as String? ??
        'Unknown';

    final condition = payload['condition'] as String? ?? prediction;

    final treatments = payload['suggested_treatments'];
    final treatmentText = treatments is List
        ? treatments.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).join('، ')
        : null;

    final isHealthy = (payload['is_healthy'] as bool?) ??
        ((payload['condition'] as String?)?.toLowerCase().contains('healthy') ?? false) ||
        prediction.toLowerCase().contains('healthy');

    return PlantDiseaseResponse(
      prediction: prediction,
      condition: condition,
      confidence: _d(payload['confidence'] ?? payload['score'] ?? 0),
      isHealthy: isHealthy,
      cropType: payload['crop_type'] as String? ?? payload['crop_type_ar'] as String? ?? payload['crop_type_en'] as String?,
      description: payload['description'] as String? ?? payload['message'] as String?,
      treatment: payload['treatment'] as String? ??
          payload['recommendation'] as String? ??
          treatmentText,
    );
  }

  final String  prediction;
  final String  condition;
  final double  confidence;
  final bool    isHealthy;
  final String? cropType;
  final String? description;
  final String? treatment;

  String get confidencePct => '${(confidence * 100).toStringAsFixed(1)}%';
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int)    return v.toDouble();
  if (v is String) {
    final cleaned = v.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned) ?? 0.0;
    if (v.contains('%')) return parsed / 100.0;
    return parsed;
  }
  return 0.0;
}
