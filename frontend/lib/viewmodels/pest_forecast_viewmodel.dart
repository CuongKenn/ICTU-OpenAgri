import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/pest_service.dart';

class PestForecastViewModel extends ChangeNotifier {
  final PestService _pestService = PestService();

  PestRiskForecastResponseDTO? _forecast;
  bool _isLoading = false;
  String? _errorMessage;

  PestRiskForecastResponseDTO? get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPestRiskForecast({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    List<String>? pestNames,
    int yearsBack = 5,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(
          '🐛 Fetching pest forecast for: $latitude, $longitude ($yearsBack years)');
      _forecast = await _pestService.getPestRiskForecast(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        pestNames: pestNames,
        yearsBack: yearsBack,
      );
      debugPrint(
          '✅ Forecast received: ${_forecast?.pestSummary.length} pests, ${_forecast?.warnings.length} warnings');
      debugPrint(
          '📊 Pest summary keys: ${_forecast?.pestSummary.keys.toList()}');
    } catch (e) {
      debugPrint('❌ Error fetching forecast: $e');
      _errorMessage = e.toString();
      _forecast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
