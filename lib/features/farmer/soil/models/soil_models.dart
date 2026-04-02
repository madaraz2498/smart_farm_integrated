// POST /soil/analyze-soil — form-encoded (FastAPI Form fields)
class SoilAnalysisRequest {
  const SoilAnalysisRequest({
    required this.ph,
    this.userId,
    this.moisture,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
  });

  final double ph;
  final String? userId;
  final double? moisture, nitrogen, phosphorus, potassium;

  SoilAnalysisRequest copyWith({String? userId}) => SoilAnalysisRequest(
    ph: ph,
    userId: userId ?? this.userId,
    moisture: moisture,
    nitrogen: nitrogen,
    phosphorus: phosphorus,
    potassium: potassium,
  );

  /// JSON-ready — used with ApiClient.post()
  Map<String, dynamic> toJson() => {
        'ph': ph,
        if (userId     != null) 'user_id':  int.tryParse(userId!) ?? userId!,
        if (moisture   != null) 'moisture': moisture,
        if (nitrogen   != null) 'N':        nitrogen,
        if (phosphorus != null) 'P':        phosphorus,
        if (potassium  != null) 'K':        potassium,
      };
}

class SoilAnalysisResponse {
  const SoilAnalysisResponse({
    required this.soilType,
    required this.fertilityLevel,
    this.recommendations = const [],
  });

  factory SoilAnalysisResponse.fromJson(Map<String, dynamic> j) =>
      SoilAnalysisResponse(
        soilType:       j['soil_type']       as String? ?? j['type'] as String? ?? 'Unknown',
        fertilityLevel: j['fertility_level'] as String? ?? j['fertility'] as String? ?? 'Unknown',
        recommendations: (j['recommendations'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  final String       soilType, fertilityLevel;
  final List<String> recommendations;
}
