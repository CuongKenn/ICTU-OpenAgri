import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/weather_service.dart';

class DashboardViewModel extends ChangeNotifier {
  // State
  bool _isLoading = true;
  DashboardStats _stats = DashboardStats.getMockData();
  List<FieldStatus> _fields = [];
  List<ActivityLog> _activities = [];
  WeatherData _weather = WeatherData.getMockData();

  // Getters
  bool get isLoading => _isLoading;
  DashboardStats get stats => _stats;
  List<FieldStatus> get fields => _fields;
  List<ActivityLog> get activities => _activities;
  WeatherData get weather => _weather;

  final WeatherService _weatherService = WeatherService();

  // Initialize data
  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load mock data for stats, fields, and activities
      // In a real app, these would be API calls too
      _stats = DashboardStats.getMockData();
      _fields = FieldStatus.getMockList();
      _activities = ActivityLog.getMockList();

      // Fetch real weather data
      try {
        final position = await _weatherService.getCurrentLocation();
        final weatherData = await _weatherService.getWeatherData(
          position.latitude,
          position.longitude,
        );
        _weather = _mapToWeatherData(weatherData);
      } catch (e) {
        debugPrint('Error fetching weather: $e');
        _weather = WeatherData.getMockData();
      }
    } catch (e) {
      debugPrint('Error initializing dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
