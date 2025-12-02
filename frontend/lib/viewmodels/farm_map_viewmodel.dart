// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/api_models.dart';
import '../models/crop_field.dart';
import '../services/farm_service.dart';
import '../services/location_service.dart';

class FarmMapViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FarmService _farmService = FarmService();

  List<CropField> _fields = [];
  CropField? _selectedField;
  List<LatLng> _newFieldPoints = [];
  bool _isDrawingMode = false;
  bool _isDrawingComplete = false;
  LatLng? _currentLocation;
  bool _isLoading = false;

  // Getters
  List<CropField> get fields => _fields;
  CropField? get selectedField => _selectedField;
  List<LatLng> get newFieldPoints => _newFieldPoints;
  bool get isDrawingMode => _isDrawingMode;
  bool get isDrawingComplete => _isDrawingComplete;
  LatLng? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;

  // Initialize
  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    await _getCurrentLocation();
    await _fetchFarms();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchFarms() async {
    try {
      final farmDtos = await _farmService.getMyFarms();
      _fields = farmDtos.map((dto) => _mapDtoToCropField(dto)).toList();
    } catch (e) {
      debugPrint('Error fetching farms: $e');
      // Fallback to mock data if fetch fails? Or empty?
      // _fields = CropField.getMockFields();
    }
  }

  CropField _mapDtoToCropField(FarmAreaResponseDTO dto) {
    final center = dto.coordinates.isNotEmpty
        ? _calculateCenter(dto.coordinates)
        : const LatLng(0, 0);

    return CropField(
      id: dto.id.toString(),
      name: dto.name,
      cropType: dto.cropType ?? 'Khác',
      area: dto.areaSize ?? 0.0,
      ndviValue: 0.0, // Not available in farm DTO yet
      trendDirection: 'stable',
      lastUpdated: DateTime.now(), // Not available
      ndviHistory: [], // Not available
      imageUrl: '',
      polygonPoints: dto.coordinates,
      center: center,
    );
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();
    }
  }

  // Selection
  void selectField(CropField? field) {
    _selectedField = field;
    notifyListeners();
  }

  // Drawing Mode
  void startDrawingMode() {
    _isDrawingMode = true;
    _newFieldPoints = [];
    _selectedField = null;
    _isDrawingComplete = false;
    notifyListeners();
  }

  void cancelDrawing() {
    _isDrawingMode = false;
    _newFieldPoints = [];
    _isDrawingComplete = false;
    notifyListeners();
  }

  void addPoint(LatLng point) {
    if (!_isDrawingMode || _newFieldPoints.length >= 4) return;

    _newFieldPoints.add(point);

    if (_newFieldPoints.length == 4) {
      _isDrawingComplete = true;
    }

    notifyListeners();
  }

  void resetDrawingComplete() {
    _isDrawingComplete = false;
    notifyListeners();
  }

  // Save new field
  Future<void> saveNewField(String name, String cropType, double area) async {
    _isLoading = true;
    notifyListeners();

    try {
      final createDto = FarmAreaCreateDTO(
        name: name,
        cropType: cropType,
        areaSize: area,
        coordinates: _newFieldPoints,
        description: 'Created from mobile app',
      );

      final newFarm = await _farmService.createFarm(createDto);

      // Add to local list
      _fields.add(_mapDtoToCropField(newFarm));

      _isDrawingMode = false;
      _newFieldPoints = [];
      _isDrawingComplete = false;
    } catch (e) {
      debugPrint('Error creating farm: $e');
      // Handle error (show toast/snackbar via UI)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helpers
  double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Shoelace formula
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = (area.abs() / 2.0);

    // Convert to hectares (approximation: 1 degree ≈ 111km)
    area = area * 111 * 111 * 100;
    return area;
  }

  LatLng _calculateCenter(List<LatLng> points) {
    double lat = 0.0;
    double lng = 0.0;
    for (var point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}
