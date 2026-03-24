// POST /animals/estimate-weight — multipart field: "file"
class AnimalWeightResponse {
  const AnimalWeightResponse({
    required this.estimatedWeight,
    required this.confidence,
    required this.animalType,
  });

  factory AnimalWeightResponse.fromJson(Map<String, dynamic> j) =>
      AnimalWeightResponse(
        estimatedWeight: _d(j['estimated_weight'] ?? j['weight_kg'] ?? j['weight'] ?? 0),
        confidence:      _d(j['confidence'] ?? j['score'] ?? 0),
        animalType:      j['animal_type'] as String? ?? j['animal'] as String? ?? 'Unknown',
      );

  final double estimatedWeight;
  final double confidence;
  final String animalType;

  String get weightDisplay => '${estimatedWeight.toStringAsFixed(1)} kg';
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int)    return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
