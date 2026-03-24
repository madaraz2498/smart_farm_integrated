// POST /soil/analyze-soil — form-encoded (FastAPI Form fields)
class SoilAnalysisRequest {
  const SoilAnalysisRequest({
    required this.ph,
    this.moisture,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
  });

  final double ph;
  final double? moisture, nitrogen, phosphorus, potassium;

  /// form-encoded — used with ApiClient.postForm()
  Map<String, String> toForm() => {
        'ph': ph.toString(),
        if (moisture   != null) 'moisture': moisture!.toString(),
        if (nitrogen   != null) 'N':        nitrogen!.toString(),
        if (phosphorus != null) 'P':        phosphorus!.toString(),
        if (potassium  != null) 'K':        potassium!.toString(),
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
