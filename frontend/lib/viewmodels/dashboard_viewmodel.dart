import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/dashboard_data.dart';
import '../services/farm_service.dart';
import '../services/weather_service.dart';

class DashboardViewModel extends ChangeNotifier {
  // State
  bool _isLoading = true;
  DashboardStats _stats = DashboardStats.empty();
  List<FieldStatus> _fields = [];
  List<ActivityLog> _activities = [];
  WeatherData _weather = WeatherData.getMockData();
  String? _selectedFarmId;

  // Getters
  bool get isLoading => _isLoading;
  DashboardStats get stats => _stats;
  List<FieldStatus> get fields => _fields;
  List<ActivityLog> get activities => _activities;
  WeatherData get weather => _weather;
  String? get selectedFarmId => _selectedFarmId;

  final WeatherService _weatherService = WeatherService();
  final FarmService _farmService = FarmService();

  // Initialize data
  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load mock data for activities
      _activities = ActivityLog.getMockList();

      // Fetch real farms
      await _fetchFarms();

      // Stop loading to show UI immediately
      _isLoading = false;
      notifyListeners();

      // Fetch real weather data in background
      await _fetchWeatherData();
    } catch (e) {
      debugPrint('Error initializing dashboard: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFarms() async {
    try {
      final farmDtos = await _farmService.getMyFarms();
      _fields = farmDtos.map((dto) => _mapDtoToFieldStatus(dto)).toList();

      if (_fields.isNotEmpty && _selectedFarmId == null) {
        _selectedFarmId = _fields.first.id;
      }
      _updateStats();
    } catch (e) {
      debugPrint('Error fetching farms: $e');
      _fields = []; // No mock data on error
      _updateStats();
    }
  }

  void _updateStats() {
    double totalArea = 0;
    double totalNdvi = 0;

    if (_fields.isNotEmpty) {
      for (var field in _fields) {
        totalArea += field.area;
        totalNdvi += field.ndvi;
      }
      totalNdvi = totalNdvi / _fields.length;
    }

    _stats = DashboardStats(
      totalFields: _fields.length,
      totalArea: totalArea,
      averageNDVI: totalNdvi,
      activeAlerts: 0, // Placeholder
      soilMoisture: 0, // Placeholder
      weatherCondition: _weather.condition,
      temperature: _weather.temperature,
    );
  }

  void selectFarm(String id) {
    _selectedFarmId = id;
    notifyListeners();
  }

  FieldStatus _mapDtoToFieldStatus(FarmAreaResponseDTO dto) {
    return FieldStatus(
      id: dto.id.toString(),
      name: dto.name,
      status: 'healthy', // Default status as backend doesn't provide it yet
      ndvi: 0.0, // Default
      area: dto.areaSize ?? 0.0,
      lastUpdate: 'Hôm nay',
    );
  }

  Future<void> _fetchWeatherData() async {
    try {
      final position = await _weatherService.getCurrentLocation();
      final weatherData = await _weatherService.getWeatherData(
        position.latitude,
        position.longitude,
      );
      _weather = _mapToWeatherData(weatherData);
      _updateStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      // Keep using mock data if fetch fails
    }
  }

  WeatherData _mapToWeatherData(Map<String, dynamic> data) {
    final current = data['current'];
    final weatherCode = current['weather_code'] as int;
    final weatherInfo = _weatherService.getWeatherInfo(weatherCode);

    return WeatherData(
      condition: weatherInfo['desc'] ?? 'Không xác định',
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      rainfall: (current['precipitation'] as num).toDouble(),
      icon: _getWeatherEmoji(weatherInfo['icon']),
    );
  }

  String _getWeatherEmoji(String? iconName) {
    switch (iconName) {
      case 'clear_day':
        return '☀️';
      case 'partly_cloudy_day':
        return '⛅';
      case 'cloudy':
        return '☁️';
      case 'foggy':
        return '🌫️';
      case 'rainy_light':
        return '🌦️';
      case 'rainy':
        return '🌧️';
      case 'rainy_heavy':
        return '⛈️';
      case 'thunderstorm':
        return '⛈️';
      default:
        return '☁️';
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await initData();
  }
}
