// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class PestService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<PestRiskForecastResponseDTO> getPestRiskForecast({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    List<String>? pestNames,
    int yearsBack = 5,
  }) async {
    try {
      final token = await _authService.getToken();
      debugPrint(
          '🌐 Calling /pest/forecast with params: lat=$latitude, lon=$longitude, years=$yearsBack');
      final response = await _apiService.client.get(
        '/pest/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          if (pestNames != null) 'pest_names': pestNames,
          'years_back': yearsBack,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      // debugPrint('📦 Response data keys: ${response.data?.keys?.toList()}');
      debugPrint(
          '📊 Pest summary: ${response.data?['pest_summary']?.keys?.toList()}');

      return PestRiskForecastResponseDTO.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ PestService error: $e');
      throw Exception('Failed to get pest forecast: $e');
    }
  }

  Future<SpeciesSearchResponseDTO> searchSpecies(String query,
      {int limit = 20}) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.get(
        '/pest/search',
        queryParameters: {
          'query': query,
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return SpeciesSearchResponseDTO.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to search species: $e');
    }
  }
}
