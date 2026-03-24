// POST /plants/detect — multipart field: "file"
class PlantDiseaseResponse {
  const PlantDiseaseResponse({
    required this.prediction,
    required this.confidence,
    required this.isHealthy,
    this.description,
    this.treatment,
  });

  factory PlantDiseaseResponse.fromJson(Map<String, dynamic> j) =>
      PlantDiseaseResponse(
        prediction:  j['prediction']  as String? ?? j['disease'] as String? ?? j['class'] as String? ?? 'Unknown',
        confidence:  _d(j['confidence'] ?? j['score'] ?? 0),
        isHealthy:   j['is_healthy']  as bool? ??
                     (j['prediction'] as String? ?? '').toLowerCase().contains('healthy'),
        description: j['description']   as String?,
        treatment:   j['treatment']     as String? ?? j['recommendation'] as String?,
      );

  final String  prediction;
  final double  confidence;
  final bool    isHealthy;
  final String? description;
  final String? treatment;

  String get confidencePct => '${(confidence * 100).toStringAsFixed(1)}%';
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int)    return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
