// POST /fruits/analyze-fruit — multipart field: "file"
class FruitQualityResponse {
  const FruitQualityResponse({
    required this.grade,
    required this.ripeness,
    required this.defects,
    required this.confidence,
  });

  factory FruitQualityResponse.fromJson(Map<String, dynamic> j) {
    final grade = j['grade'] as String? ?? j['quality_grade'] as String? ?? 'C';
    return FruitQualityResponse(
      grade:      grade,
      ripeness:   j['ripeness']  as String? ?? j['ripeness_level']    as String? ?? 'Unknown',
      defects:    j['defects']   as String? ?? j['defect_description'] as String? ?? 'None detected',
      confidence: _d(j['confidence'] ?? j['score'] ?? 0),
    );
  }

  final String grade, ripeness, defects;
  final double confidence;

  String get gradeLabel => switch (grade.toUpperCase()) {
        'A' => 'Premium quality — Ready for market',
        'B' => 'Standard quality — Good for market',
        _   => 'Below standard — Not recommended for market',
      };
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int)    return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
