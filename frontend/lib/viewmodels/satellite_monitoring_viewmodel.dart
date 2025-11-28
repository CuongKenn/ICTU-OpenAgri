import 'package:flutter/material.dart';
import '../models/crop_field.dart';

class SatelliteMonitoringViewModel extends ChangeNotifier {
  List<CropField> _fields = [];
  CropField? _selectedField;

  String _mapMode = 'NDVI';
  String _mapLayerType = 'Satellite';

  String _activeControlTab = 'filter';
  DateTime _selectedDate = DateTime(2024, 9);
  String _selectedDataLayer = 'Tất cả';
  bool _showCropType = true;
  bool _showHealth = true;

  // Getters
  List<CropField> get fields => _fields;
  CropField? get selectedField => _selectedField;
  String get mapMode => _mapMode;
  String get mapLayerType => _mapLayerType;
  String get activeControlTab => _activeControlTab;
  DateTime get selectedDate => _selectedDate;
  String get selectedDataLayer => _selectedDataLayer;
  bool get showCropType => _showCropType;
  bool get showHealth => _showHealth;

  // Initialize
  void initData({String? initialFieldId}) {
    _fields = CropField.getMockFields();
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
    notifyListeners();
  }

  // Actions
  void selectField(CropField? field) {
    _selectedField = field;
    notifyListeners();
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
