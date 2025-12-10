// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/api_models.dart';
import '../models/crop_field.dart';
import '../services/analysis_service.dart';
import '../services/soil_service.dart';
import '../services/farm_service.dart';

class SatelliteMonitoringViewModel extends ChangeNotifier {
  final FarmService _farmService = FarmService();
  final AnalysisService _analysisService = AnalysisService();
  final SoilService _soilService = SoilService();
  final Distance _distance = const Distance();
  static const double _maxSoilMatchKm = 150.0;

  List<CropField> _fields = [];
  CropField? _selectedField;
  bool _isLoading = false;
  List<SoilAnalysisModel> _soilData = [];

  String _mapMode = 'NDVI';
  String _mapLayerType = 'Satellite';

  String _activeControlTab = 'filter';
  DateTime _selectedDate = DateTime.now();
  String _selectedDataLayer = 'Tất cả';
  bool _showCropType = true;
  bool _showHealth = true;

  // Getters
  List<CropField> get fields => _fields;
  CropField? get selectedField => _selectedField;
  bool get isLoading => _isLoading;
  List<SoilAnalysisModel> get soilData => _soilData;
  String get mapMode => _mapMode;
  String get mapLayerType => _mapLayerType;
  String get activeControlTab => _activeControlTab;
  DateTime get selectedDate => _selectedDate;
  String get selectedDataLayer => _selectedDataLayer;
  bool get showCropType => _showCropType;
  bool get showHealth => _showHealth;

  // Initialize
  Future<void> initData({String? initialFieldId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final farmDtos = await _farmService.getMyFarms();
      _fields = farmDtos.map((dto) => _mapDtoToCropField(dto)).toList();

      // Fetch satellite data for ALL fields in parallel
      await Future.wait([
        _fetchAllSatelliteData(),
        _fetchSoilData(),
      ]);

      if (initialFieldId != null) {
        try {
          _selectedField = _fields.firstWhere((f) => f.id == initialFieldId);
        } catch (e) {
          if (_fields.isNotEmpty) {
            _selectedField = _fields.first;
          }
        }
      } else if (_fields.isNotEmpty) {
        _selectedField = _fields.first;
      }
    } catch (e) {
      // API failed - keep empty list, don't use mock data
      _fields = [];
      _selectedField = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAllSatelliteData() async {
    // Fetch satellite data for all fields in parallel
    await Future.wait(_fields.map((field) => _fetchSatelliteData(field)));
  }

  Future<void> _fetchSoilData() async {
    try {
      _soilData = await _soilService.getSoilData();
    } catch (_) {
      _soilData = [];
    }
  }

  Future<void> _fetchSatelliteData(CropField field) async {
    try {
      // Calculate bbox
      final bbox = _calculateBBox(field.polygonPoints);

      // Fetch NDVI from DB (fast)
      final ndviRequest = NDVIRequest(
        farmId: int.tryParse(field.id),
        bbox: bbox,
        startDate:
            _selectedDate.subtract(const Duration(days: 30)).toIso8601String(),
        endDate: _selectedDate.toIso8601String(),
      );
      final ndviResponse = await _analysisService.calculateNDVI(ndviRequest);

      // Fetch Soil Moisture from DB (fast - cached from scheduler)
      double soilMoisture = 0.0;
      String soilMoistureStatus = 'Chưa có dữ liệu';
      try {
        final smRequest = SoilMoistureQueryRequest(
          farmId: int.tryParse(field.id),
          bbox: bbox,
          startDate: _selectedDate
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          endDate: _selectedDate.toIso8601String(),
        );
        final smResponse = await _analysisService.getSoilMoisture(smRequest);

        if (smResponse.status == 'success') {
          // Convert 0-1 index to percentage
          soilMoisture = smResponse.meanValue * 100;

          if (soilMoisture < 30) {
            soilMoistureStatus = 'Thiếu nước';
          } else if (soilMoisture < 70) {
            soilMoistureStatus = 'Đủ ẩm';
          } else {
            soilMoistureStatus = 'Dư nước';
          }
        }
      } catch (e) {
        // Soil moisture fetch failed silently
      }

      // Update field with new data
      // Since CropField is immutable, we replace it in the list
      final updatedField = CropField(
        id: field.id,
        name: field.name,
        cropType: field.cropType,
        area: field.area,
        ndviValue: ndviResponse.meanNdvi,
        trendDirection: 'stable', // Calculate based on history
        lastUpdated: DateTime.now(),
        ndviHistory: ndviResponse.chartData.map((d) {
          return NDVIDataPoint(
            date: DateTime.parse(d['date']),
            value: (d['value'] as num).toDouble(),
          );
        }).toList(),
        imageUrl: field.imageUrl,
        polygonPoints: field.polygonPoints,
        center: field.center,
        ndviStatus: _getNdviStatus(ndviResponse.meanNdvi),
        soilMoisture: soilMoisture,
        soilMoistureStatus: soilMoistureStatus,
      );

      _updateFieldInList(updatedField);
      _selectedField = updatedField;
    } catch (e) {
      // Satellite data fetch failed silently
    }
  }

  void _updateFieldInList(CropField updatedField) {
    final index = _fields.indexWhere((f) => f.id == updatedField.id);
    if (index != -1) {
      _fields[index] = updatedField;
    }
  }

  List<double> _calculateBBox(List<LatLng> points) {
    if (points.isEmpty) return [0, 0, 0, 0];
    double minLon = points[0].longitude;
    double minLat = points[0].latitude;
    double maxLon = points[0].longitude;
    double maxLat = points[0].latitude;

    for (var p in points) {
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
    }
    return [minLon, minLat, maxLon, maxLat];
  }

  CropField _mapDtoToCropField(FarmAreaResponseDTO dto) {
    // Calculate center
    double lat = 0;
    double lng = 0;
    if (dto.coordinates.isNotEmpty) {
      for (var p in dto.coordinates) {
        lat += p.latitude;
        lng += p.longitude;
      }
      lat /= dto.coordinates.length;
      lng /= dto.coordinates.length;
    }

    return CropField(
      id: dto.id.toString(),
      name: dto.name,
      cropType: dto.cropType ?? 'Chưa xác định',
      area: dto.areaSize ?? 0.0,
      ndviValue: 0.0, // Initial value
      trendDirection: 'stable',
      lastUpdated: DateTime.now(),
      ndviHistory: [],
      imageUrl: '',
      polygonPoints: dto.coordinates,
      center: LatLng(lat, lng),
    );
  }

  String _getNdviStatus(double value) {
    if (value < 0.2) return 'Kém';
    if (value < 0.4) return 'Trung bình';
    if (value < 0.6) return 'Khá';
    if (value < 0.8) return 'Tốt';
    return 'Rất tốt';
  }

  // Actions
  void selectField(CropField? field) {
    _selectedField = field;
    // No need to fetch - data already loaded in initData
    notifyListeners();
  }

  SoilAnalysisModel? nearestSoilData() {
    if (_selectedField == null || _soilData.isEmpty) return null;
    final center = _selectedField!.center;
    SoilAnalysisModel? best;
    double? bestDist;
    for (final item in _soilData) {
      if (item.coordinate == null) continue;
      final d = _distance.as(
        LengthUnit.Kilometer,
        center,
        LatLng(item.coordinate!.latitude, item.coordinate!.longitude),
      );
      if (bestDist == null || d < bestDist) {
        bestDist = d;
        best = item;
      }
    }
    if (bestDist != null && bestDist > _maxSoilMatchKm) {
      return null;
    }
    return best;
  }

  double? distanceToSoil(SoilAnalysisModel soil) {
    if (_selectedField == null || soil.coordinate == null) return null;
    return _distance.as(
      LengthUnit.Kilometer,
      _selectedField!.center,
      LatLng(soil.coordinate!.latitude, soil.coordinate!.longitude),
    );
  }

  void setMapMode(String mode) {
    _mapMode = mode;
    notifyListeners();
  }

  void setMapLayerType(String type) {
    _mapLayerType = type;
    notifyListeners();
  }

  void setActiveControlTab(String tab) {
    _activeControlTab = tab;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedDataLayer(String layer) {
    _selectedDataLayer = layer;
    notifyListeners();
  }

  void toggleShowCropType(bool value) {
    _showCropType = value;
    notifyListeners();
  }

  void toggleShowHealth(bool value) {
    _showHealth = value;
    notifyListeners();
  }

  // Helpers
  String getMapTileUrl() {
    if (_mapLayerType == 'Satellite') {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    } else if (_mapLayerType == 'Terrain') {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'; // Standard OSM as terrain placeholder
    } else {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  Color getNDVIColor(double value) {
    if (value < 0.2) return const Color(0xFFEF4444); // Red - Dead/Soil
    if (value < 0.4) return const Color(0xFFF59E0B); // Orange - Unhealthy
    if (value < 0.6) return const Color(0xFFEAB308); // Yellow - Moderate
    if (value < 0.8) return const Color(0xFF10B981); // Green - Healthy
    return const Color(0xFF059669); // Dark Green - Very Healthy
  }

  Color getMoistureColor(double value) {
    if (value < 30) return const Color(0xFFEF4444); // Dry
    if (value < 50) return const Color(0xFFF59E0B); // Moderate
    if (value < 70) return const Color(0xFF3B82F6); // Moist
    return const Color(0xFF1D4ED8); // Wet
  }
}
