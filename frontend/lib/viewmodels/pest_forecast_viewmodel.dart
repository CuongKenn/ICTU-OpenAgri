import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/pest_service.dart';

class PestForecastViewModel extends ChangeNotifier {
  final PestService _pestService = PestService();

  PestRiskForecastResponseDTO? _forecast;
  bool _isLoading = false;
  String? _errorMessage;

  // Cache by coordinates (rounded to 3 decimal places ~100m precision)
  final Map<String, PestRiskForecastResponseDTO> _cache = {};
  String? _currentCacheKey;

  PestRiskForecastResponseDTO? get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _getCacheKey(double lat, double lon) {
    // Round to 3 decimal places (~100m precision) for cache key
    return '${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}';
  }

  Future<void> fetchPestRiskForecast({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    List<String>? pestNames,
    int yearsBack = 5,
  }) async {
    final cacheKey = _getCacheKey(latitude, longitude);

    // Return cached data if available
    if (_cache.containsKey(cacheKey)) {
      _forecast = _cache[cacheKey];
      _currentCacheKey = cacheKey;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _forecast = await _pestService.getPestRiskForecast(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        pestNames: pestNames,
        yearsBack: yearsBack,
      );
      // Cache the result
      if (_forecast != null) {
        _cache[cacheKey] = _forecast!;
        _currentCacheKey = cacheKey;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _forecast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _cache.clear();
    _currentCacheKey = null;
  }
}
