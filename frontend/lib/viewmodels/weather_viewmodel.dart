import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/weather_service.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  // State
  bool _isLoading = true;
  String _locationName = "Đang tải...";
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  LatLng _currentLocation = const LatLng(21.0285, 105.8542);
  String _forecastTab = 'hourly'; // hourly, daily, weekly
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String get locationName => _locationName;
  Map<String, dynamic>? get weatherData => _weatherData;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get showSearchResults => _showSearchResults;
  LatLng get currentLocation => _currentLocation;
  String get forecastTab => _forecastTab;
  String? get errorMessage => _errorMessage;

  // Setters
  void setForecastTab(String tab) {
    _forecastTab = tab;
    notifyListeners();
  }

  void toggleSearchResults(bool show) {
    _showSearchResults = show;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize weather data
  Future<void> initWeather() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await _weatherService.getCurrentLocation();
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationName = "Vị trí hiện tại";

      await fetchWeather(_currentLocation.latitude, _currentLocation.longitude);
    } catch (e) {
      // Fallback to default location
      await fetchWeather(_currentLocation.latitude, _currentLocation.longitude);
    }
  }

  // Fetch weather data
  Future<void> fetchWeather(double lat, double lon) async {
    try {
      final data = await _weatherService.getWeatherData(lat, lon);
      _weatherData = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể tải dữ liệu thời tiết: $e';
      notifyListeners();
    }
  }

  // Search location
  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      final results = await _weatherService.searchLocation(query);
      _searchResults = results;
      _showSearchResults = true;
      notifyListeners();
    } catch (e) {
      // Handle search error silently or show message
      debugPrint('Search error: $e');
    }
  }

  // Select location
  void selectLocation(Map<String, dynamic> location) {
    final lat = location['lat'];
    final lon = location['lon'];
    final name = location['name'];

    _currentLocation = LatLng(lat, lon);
    _locationName = name;
    _showSearchResults = false;
    _searchResults = [];
    _isLoading = true;
    notifyListeners();

    fetchWeather(lat, lon);
  }

  // Helper to get weather info
  Map<String, dynamic> getWeatherInfo(int code) {
    return _weatherService.getWeatherInfo(code);
  }
}
