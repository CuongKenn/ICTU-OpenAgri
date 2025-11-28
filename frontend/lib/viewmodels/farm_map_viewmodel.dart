import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/crop_field.dart';

class FarmMapViewModel extends ChangeNotifier {
  List<CropField> _fields = [];
  CropField? _selectedField;
  List<LatLng> _newFieldPoints = [];
  bool _isDrawingMode = false;
  bool _isDrawingComplete = false;

  // Getters
  List<CropField> get fields => _fields;
  CropField? get selectedField => _selectedField;
  List<LatLng> get newFieldPoints => _newFieldPoints;
  bool get isDrawingMode => _isDrawingMode;
  bool get isDrawingComplete => _isDrawingComplete;

  // Initialize
  void initData() {
    _fields = CropField.getMockFields();
    notifyListeners();
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
  void saveNewField(String name, String cropType, double area) {
    final newField = CropField(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      cropType: cropType,
      area: area,
      ndviValue: 0.0, // Default
      trendDirection: 'stable',
      lastUpdated: DateTime.now(),
      ndviHistory: [],
      imageUrl: '',
      polygonPoints: List.from(_newFieldPoints),
      center: _calculateCenter(_newFieldPoints),
    );

    _fields.add(newField);
    _isDrawingMode = false;
    _newFieldPoints = [];
    _isDrawingComplete = false;
    notifyListeners();
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
