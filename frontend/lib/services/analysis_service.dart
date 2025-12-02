// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/api_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AnalysisService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // NDVI
  Future<NDVIResponse> calculateNDVI(NDVIRequest request) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.post(
        '/ndvi/calculate',
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return NDVIResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to calculate NDVI: $e');
    }
  }

  // Soil Moisture
  Future<SoilMoistureResponse> calculateSoilMoisture(
      SoilMoistureRequest request) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.post(
        '/soil-moisture/calculate',
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return SoilMoistureResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to calculate Soil Moisture: $e');
    }
  }

  // Disease Detection
  Future<DiseasePredictionDTO> predictDisease(XFile imageFile) async {
    try {
      final token = await _authService.getToken();

      final String fileName = imageFile.name;
      final bytes = await imageFile.readAsBytes();

      final FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _apiService.client.post(
        '/disease-detection/predict',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return DiseasePredictionDTO.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to predict disease: $e');
    }
  }
}
