import 'package:dio/dio.dart';
import '../models/soil_analysis_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SoilAnalysisService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<SoilAnalysisResult> analyzeSoil({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print("DEBUG: SoilAnalysisService - Starting analysis for $latitude, $longitude");
      
      final token = await _authService.getToken();
      print("DEBUG: SoilAnalysisService - Got token: ${token?.substring(0, 20)}...");
      
      final response = await _apiService.client.get(
        '/soil/analyze',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        ),
      );

      print("DEBUG: SoilAnalysisService - Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        print("DEBUG: SoilAnalysisService - Parsing response data");
        final result = SoilAnalysisResult.fromJson(response.data);
        print("DEBUG: SoilAnalysisService - Success! Got ${result.cropRecommendations.length} recommendations");
        return result;
      } else {
        throw Exception('Failed to analyze soil: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print("DEBUG: SoilAnalysisService - DioException: ${e.message}");
      print("DEBUG: SoilAnalysisService - Response: ${e.response?.data}");
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print("DEBUG: SoilAnalysisService - Exception: $e");
      throw Exception('Error analyzing soil: $e');
    }
  }
}
