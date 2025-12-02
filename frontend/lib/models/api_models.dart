// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:latlong2/latlong.dart';

// --- Farm Models ---

class FarmAreaCreateDTO {
  final String name;
  final String? description;
  final List<LatLng> coordinates;
  final double? areaSize;
  final String? cropType;

  FarmAreaCreateDTO({
    required this.name,
    this.description,
    required this.coordinates,
    this.areaSize,
    this.cropType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'coordinates': coordinates
          .map((c) => {'lat': c.latitude, 'lng': c.longitude})
          .toList(),
      'area_size': areaSize,
      'crop_type': cropType,
    };
  }
}

class FarmAreaResponseDTO {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final List<LatLng> coordinates;
  final double? areaSize;
  final String? cropType;

  FarmAreaResponseDTO({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.coordinates,
    this.areaSize,
    this.cropType,
  });

  factory FarmAreaResponseDTO.fromJson(Map<String, dynamic> json) {
    return FarmAreaResponseDTO(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      coordinates: (json['coordinates'] as List)
          .map((c) => LatLng(c['lat'], c['lng']))
          .toList(),
      areaSize: json['area_size'],
      cropType: json['crop_type'],
    );
  }
}

class AdminFarmAreaResponseDTO extends FarmAreaResponseDTO {
  final String userEmail;
  final String? userFullName;
  final String username;

  AdminFarmAreaResponseDTO({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    required super.coordinates,
    super.areaSize,
    super.cropType,
    required this.userEmail,
    this.userFullName,
    required this.username,
  });

  factory AdminFarmAreaResponseDTO.fromJson(Map<String, dynamic> json) {
    return AdminFarmAreaResponseDTO(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      coordinates: (json['coordinates'] as List)
          .map((c) => LatLng(c['lat'], c['lng']))
          .toList(),
      areaSize: json['area_size'],
      cropType: json['crop_type'],
      userEmail: json['user_email'],
      userFullName: json['user_full_name'],
      username: json['username'],
    );
  }
}

// --- NDVI Models ---

class NDVIRequest {
  final int? farmId;
  final List<double> bbox; // [min_lon, min_lat, max_lon, max_lat]
  final String startDate;
  final String endDate;

  NDVIRequest({
    this.farmId,
    required this.bbox,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'bbox': bbox,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}

class NDVIResponse {
  final String status;
  final String ndviGeotiff;
  final String imageBase64;
  final double meanNdvi;
  final double minNdvi;
  final double maxNdvi;
  final String acquisitionDate;
  final List<Map<String, dynamic>> chartData;

  NDVIResponse({
    required this.status,
    required this.ndviGeotiff,
    required this.imageBase64,
    required this.meanNdvi,
    required this.minNdvi,
    required this.maxNdvi,
    required this.acquisitionDate,
    required this.chartData,
  });

  factory NDVIResponse.fromJson(Map<String, dynamic> json) {
    return NDVIResponse(
      status: json['status'],
      ndviGeotiff: json['ndvi_geotiff'],
      imageBase64: json['image_base64'],
      meanNdvi: json['mean_ndvi'],
      minNdvi: json['min_ndvi'],
      maxNdvi: json['max_ndvi'],
      acquisitionDate: json['acquisition_date'],
      chartData: List<Map<String, dynamic>>.from(json['chart_data']),
    );
  }
}

// --- Soil Moisture Models ---

class SoilMoistureRequest {
  final List<double> bbox;
  final String date;

  SoilMoistureRequest({
    required this.bbox,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'bbox': bbox,
      'date': date,
    };
  }
}

class SoilMoistureResponse {
  final String status;
  final String soilMoistureMap;
  final String imageBase64;
  final double meanValue;

  SoilMoistureResponse({
    required this.status,
    required this.soilMoistureMap,
    required this.imageBase64,
    required this.meanValue,
  });

  factory SoilMoistureResponse.fromJson(Map<String, dynamic> json) {
    return SoilMoistureResponse(
      status: json['status'],
      soilMoistureMap: json['soil_moisture_map'],
      imageBase64: json['image_base64'],
      meanValue: (json['mean_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// --- Pest Models ---

class PestRiskForecastResponseDTO {
  final Map<String, dynamic> location;
  final Map<String, PestSummaryDTO> pestSummary;
  final List<PestWarningDTO> warnings;
  final List<String> checkedPests;
  final int totalOccurrences;

  PestRiskForecastResponseDTO({
    required this.location,
    required this.pestSummary,
    required this.warnings,
    required this.checkedPests,
    required this.totalOccurrences,
  });

  factory PestRiskForecastResponseDTO.fromJson(Map<String, dynamic> json) {
    return PestRiskForecastResponseDTO(
      location: json['location'],
      pestSummary: (json['pest_summary'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PestSummaryDTO.fromJson(value)),
      ),
      warnings: (json['warnings'] as List)
          .map((e) => PestWarningDTO.fromJson(e))
          .toList(),
      checkedPests: List<String>.from(json['checked_pests']),
      totalOccurrences: json['total_occurrences'],
    );
  }
}

class PestSummaryDTO {
  final String pestName;
  final int? speciesKey;
  final Map<String, int> yearlyOccurrences;
  final int totalOccurrences;
  final int? mostRecentYear;

  PestSummaryDTO({
    required this.pestName,
    this.speciesKey,
    required this.yearlyOccurrences,
    required this.totalOccurrences,
    this.mostRecentYear,
  });

  factory PestSummaryDTO.fromJson(Map<String, dynamic> json) {
    return PestSummaryDTO(
      pestName: json['pest_name'],
      speciesKey: json['species_key'],
      yearlyOccurrences: Map<String, int>.from(json['yearly_occurrences']),
      totalOccurrences: json['total_occurrences'],
      mostRecentYear: json['most_recent_year'],
    );
  }
}

class PestWarningDTO {
  final String pestName;
  final String riskLevel;
  final String message;
  final int? lastSeenYear;
  final int occurrenceCount;

  PestWarningDTO({
    required this.pestName,
    required this.riskLevel,
    required this.message,
    this.lastSeenYear,
    required this.occurrenceCount,
  });

  factory PestWarningDTO.fromJson(Map<String, dynamic> json) {
    return PestWarningDTO(
      pestName: json['pest_name'],
      riskLevel: json['risk_level'],
      message: json['message'],
      lastSeenYear: json['last_seen_year'],
      occurrenceCount: json['occurrence_count'],
    );
  }
}

class SpeciesSearchResponseDTO {
  final List<SpeciesSearchDTO> results;
  final int count;

  SpeciesSearchResponseDTO({
    required this.results,
    required this.count,
  });

  factory SpeciesSearchResponseDTO.fromJson(Map<String, dynamic> json) {
    return SpeciesSearchResponseDTO(
      results: (json['results'] as List)
          .map((e) => SpeciesSearchDTO.fromJson(e))
          .toList(),
      count: json['count'],
    );
  }
}

class SpeciesSearchDTO {
  final int key;
  final String scientificName;
  final String? canonicalName;
  final String? commonName;
  final String? kingdom;

  SpeciesSearchDTO({
    required this.key,
    required this.scientificName,
    this.canonicalName,
    this.commonName,
    this.kingdom,
  });

  factory SpeciesSearchDTO.fromJson(Map<String, dynamic> json) {
    return SpeciesSearchDTO(
      key: json['key'],
      scientificName: json['scientific_name'],
      canonicalName: json['canonical_name'],
      commonName: json['common_name'],
      kingdom: json['kingdom'],
    );
  }
}

class DiseasePredictionDTO {
  final String className;
  final double confidence;
  final String? description;
  final List<String>? symptoms;
  final List<String>? treatment;
  final List<String>? prevention;
  final String? severity;

  DiseasePredictionDTO({
    required this.className,
    required this.confidence,
    this.description,
    this.symptoms,
    this.treatment,
    this.prevention,
    this.severity,
  });

  factory DiseasePredictionDTO.fromJson(Map<String, dynamic> json) {
    return DiseasePredictionDTO(
      className: json['class_name'],
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'],
      symptoms:
          json['symptoms'] != null ? List<String>.from(json['symptoms']) : null,
      treatment: json['treatment'] != null
          ? List<String>.from(json['treatment'])
          : null,
      prevention: json['prevention'] != null
          ? List<String>.from(json['prevention'])
          : null,
      severity: json['severity'],
    );
  }
}

// --- Weather Models ---

class ForecastResponseDTO {
  final LocationDTO location;
  final CurrentWeatherDTO current;
  final List<HourlyWeatherDTO> hourly;

  ForecastResponseDTO({
    required this.location,
    required this.current,
    required this.hourly,
  });

  factory ForecastResponseDTO.fromJson(Map<String, dynamic> json) {
    return ForecastResponseDTO(
      location: LocationDTO.fromJson(json['location']),
      current: CurrentWeatherDTO.fromJson(json['current']),
      hourly: (json['hourly'] as List)
          .map((e) => HourlyWeatherDTO.fromJson(e))
          .toList(),
    );
  }
}

class LocationDTO {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String? address;

  LocationDTO({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationDTO.fromJson(Map<String, dynamic> json) {
    return LocationDTO(
      name: json['name'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
    );
  }
}

class CurrentWeatherDTO {
  final String time;
  final double temperature2m;
  final int relativeHumidity2m;
  final int weatherCode;
  final double windSpeed10m;
  final double precipitation;
  final int isDay;

  CurrentWeatherDTO({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.precipitation,
    required this.isDay,
  });

  factory CurrentWeatherDTO.fromJson(Map<String, dynamic> json) {
    return CurrentWeatherDTO(
      time: json['time'],
      temperature2m: json['temperature_2m'],
      relativeHumidity2m: json['relative_humidity_2m'],
      weatherCode: json['weather_code'],
      windSpeed10m: json['wind_speed_10m'],
      precipitation: json['precipitation'],
      isDay: json['is_day'],
    );
  }
}

class HourlyWeatherDTO {
  final String time;
  final double temperature2m;
  final int relativeHumidity2m;
  final int weatherCode;
  final double windSpeed10m;
  final double precipitation;
  final double soilMoisture;

  HourlyWeatherDTO({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.precipitation,
    this.soilMoisture = 0.0,
  });

  factory HourlyWeatherDTO.fromJson(Map<String, dynamic> json) {
    return HourlyWeatherDTO(
      time: json['time'],
      temperature2m: (json['temperature_2m'] as num).toDouble(),
      relativeHumidity2m: json['relative_humidity_2m'],
      weatherCode: json['weather_code'],
      windSpeed10m: (json['wind_speed_10m'] as num).toDouble(),
      precipitation: (json['precipitation'] as num).toDouble(),
      soilMoisture: (json['soil_moisture_0_to_1cm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LocationSearchResponseDTO {
  final List<LocationSearchDTO> results;
  final int count;

  LocationSearchResponseDTO({
    required this.results,
    required this.count,
  });

  factory LocationSearchResponseDTO.fromJson(Map<String, dynamic> json) {
    return LocationSearchResponseDTO(
      results: (json['results'] as List)
          .map((e) => LocationSearchDTO.fromJson(e))
          .toList(),
      count: json['count'],
    );
  }
}

class LocationSearchDTO {
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? state;
  final String type;

  LocationSearchDTO({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.state,
    required this.type,
  });

  factory LocationSearchDTO.fromJson(Map<String, dynamic> json) {
    return LocationSearchDTO(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      country: json['country'],
      state: json['state'],
      type: json['type'],
    );
  }
}

// --- Commodity Price Models ---

class CommodityPriceDTO {
  final String id;
  final String name;
  final String nameEn;
  final String unit;
  final String category;
  final List<PricePoint> prices;
  final double? currentPrice;
  final double? priceChange24h;
  final double? priceChangePercent24h;
  final double? minPrice;
  final double? maxPrice;

  CommodityPriceDTO({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.unit,
    required this.category,
    required this.prices,
    this.currentPrice,
    this.priceChange24h,
    this.priceChangePercent24h,
    this.minPrice,
    this.maxPrice,
  });

  factory CommodityPriceDTO.fromJson(Map<String, dynamic> json) {
    return CommodityPriceDTO(
      id: json['id'],
      name: json['name'],
      nameEn: json['name_en'],
      unit: json['unit'],
      category: json['category'],
      prices:
          (json['prices'] as List).map((e) => PricePoint.fromJson(e)).toList(),
      currentPrice: json['current_price'],
      priceChange24h: json['price_change_24h'],
      priceChangePercent24h: json['price_change_percent_24h'],
      minPrice: json['min_price'],
      maxPrice: json['max_price'],
    );
  }
}

class PricePoint {
  final String date;
  final double price;

  PricePoint({
    required this.date,
    required this.price,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: json['date'],
      price: json['price'],
    );
  }
}

class CommodityPriceListResponse {
  final List<CommodityPriceDTO> commodities;
  final int total;
  final String lastUpdated;

  CommodityPriceListResponse({
    required this.commodities,
    required this.total,
    required this.lastUpdated,
  });

  factory CommodityPriceListResponse.fromJson(Map<String, dynamic> json) {
    return CommodityPriceListResponse(
      commodities: (json['commodities'] as List)
          .map((e) => CommodityPriceDTO.fromJson(e))
          .toList(),
      total: json['total'],
      lastUpdated: json['last_updated'],
    );
  }
}

class ChartDataPoint {
  final String date;
  final double price;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? volume;

  ChartDataPoint({
    required this.date,
    required this.price,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: json['date'],
      price: (json['price'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume:
          json['volume'] != null ? (json['volume'] as num).toDouble() : null,
    );
  }
}

class CommodityPriceDetailResponse {
  final CommodityPriceDTO commodity;
  final List<ChartDataPoint> chartData;
  final List<PricePoint> priceHistory;

  CommodityPriceDetailResponse({
    required this.commodity,
    required this.chartData,
    required this.priceHistory,
  });

  factory CommodityPriceDetailResponse.fromJson(Map<String, dynamic> json) {
    return CommodityPriceDetailResponse(
      commodity: CommodityPriceDTO.fromJson(json['commodity']),
      chartData: (json['chart_data'] as List)
          .map((e) => ChartDataPoint.fromJson(e))
          .toList(),
      priceHistory: (json['price_history'] as List)
          .map((e) => PricePoint.fromJson(e))
          .toList(),
    );
  }
}
