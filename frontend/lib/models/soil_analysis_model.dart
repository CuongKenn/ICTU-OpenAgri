class SoilProperties {
  final double? phWater;
  final double? phKcl;
  final double? organicCarbon;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? sandPercent;
  final double? siltPercent;
  final double? clayPercent;
  final double? soilMoisture;
  final String? soilTexture;
  final String? depth;

  SoilProperties({
    this.phWater,
    this.phKcl,
    this.organicCarbon,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.sandPercent,
    this.siltPercent,
    this.clayPercent,
    this.soilMoisture,
    this.soilTexture,
    this.depth,
  });

  factory SoilProperties.fromJson(Map<String, dynamic> json) {
    return SoilProperties(
      phWater: json['ph_water']?.toDouble(),
      phKcl: json['ph_kcl']?.toDouble(),
      organicCarbon: json['organic_carbon']?.toDouble(),
      nitrogen: json['nitrogen']?.toDouble(),
      phosphorus: json['phosphorus']?.toDouble(),
      potassium: json['potassium']?.toDouble(),
      sandPercent: json['sand_percent']?.toDouble(),
      siltPercent: json['silt_percent']?.toDouble(),
      clayPercent: json['clay_percent']?.toDouble(),
      soilMoisture: json['soil_moisture']?.toDouble(),
      soilTexture: json['soil_texture'],
      depth: json['depth'],
    );
  }
}

class CropRecommendation {
  final String cropName;
  final String cropNameVi;
  final double suitabilityScore;
  final List<String> reasons;
  final List<String> warnings;

  CropRecommendation({
    required this.cropName,
    required this.cropNameVi,
    required this.suitabilityScore,
    required this.reasons,
    required this.warnings,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      cropName: json['crop_name'] ?? '',
      cropNameVi: json['crop_name_vi'] ?? '',
      suitabilityScore: json['suitability_score']?.toDouble() ?? 0.0,
      reasons: List<String>.from(json['reasons'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}

class SoilAnalysisResult {
  final double latitude;
  final double longitude;
  final SoilProperties soilProperties;
  final List<CropRecommendation> cropRecommendations;
  final DateTime analyzedAt;
  final String dataSource;

  SoilAnalysisResult({
    required this.latitude,
    required this.longitude,
    required this.soilProperties,
    required this.cropRecommendations,
    required this.analyzedAt,
    required this.dataSource,
  });

  factory SoilAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SoilAnalysisResult(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      soilProperties: SoilProperties.fromJson(json['soil_properties'] ?? {}),
      cropRecommendations: (json['crop_recommendations'] as List?)
              ?.map((e) => CropRecommendation.fromJson(e))
              .toList() ??
          [],
      analyzedAt: DateTime.parse(json['analyzed_at']),
      dataSource: json['data_source'] ?? '',
    );
  }
}
