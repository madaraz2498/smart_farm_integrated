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

  /// Form-ready — used with ApiClient.postForm()
  Map<String, String> toForm() {
    final form = <String, String>{
      'ph': ph.toString(),
    };
    if (userId != null) form['user_id'] = userId!;
    if (moisture != null) form['moisture'] = moisture!.toString();
    if (nitrogen != null) form['n'] = nitrogen!.toString();
    if (phosphorus != null) form['p'] = phosphorus!.toString();
    if (potassium != null) form['k'] = potassium!.toString();
    return form;
  }
}

class SoilAnalysisResponse {
  const SoilAnalysisResponse({
    required this.soilType,
    required this.fertilityLevel,
    this.recommendations = const [],
  });

  factory SoilAnalysisResponse.fromJson(Map<String, dynamic> j) {
    final payload = (j['analysis'] is Map<String, dynamic>)
        ? j['analysis'] as Map<String, dynamic>
        : (j['Analysis Result'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(j['Analysis Result'] as Map)
        : (j['result'] is Map<String, dynamic>)
            ? j['result'] as Map<String, dynamic>
            : j;

    final soil = _firstString(payload, const [
          'soil_type',
          'soilType',
          'type',
          'soil',
          'Soil Type',
          'نوع_التربة',
          'نوع التربة'
        ]) ??
        _firstString(j, const ['soil_type', 'soilType', 'type', 'soil', 'Soil Type', 'نوع_التربة', 'نوع التربة']) ??
        'Unknown';

    final fertility = _firstString(payload, const [
          'fertility_level',
          'fertilityLevel',
          'fertility',
          'level',
          'Fertility',
          'مستوى_الخصوبة',
          'مستوى الخصوبة'
        ]) ??
        _firstString(j, const ['fertility_level', 'fertilityLevel', 'fertility', 'level', 'Fertility', 'مستوى_الخصوبة', 'مستوى الخصوبة']) ??
        'Unknown';

    final recs = _extractRecommendations(payload).isNotEmpty
        ? _extractRecommendations(payload)
        : _extractRecommendations(j);

    return SoilAnalysisResponse(
      soilType: soil,
      fertilityLevel: fertility,
      recommendations: recs,
    );
  }

  final String       soilType, fertilityLevel;
  final List<String> recommendations;
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

List<String> _extractRecommendations(Map<String, dynamic> map) {
  final list = map['recommendations'];
  if (list is List) {
    return list.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }
  final single = map['recommendation'] ??
      map['Recommendation'] ??
      map['advice'] ??
      map['النصيحة'] ??
      map['التوصيات'];
  if (single is String && single.trim().isNotEmpty) return [single.trim()];
  return const [];
}
