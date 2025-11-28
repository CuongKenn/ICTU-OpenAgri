import 'package:dio/dio.dart';
import '../models/api_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CommodityPriceService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<CommodityPriceListResponse> getCommodityPrices({
    String? category,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.get(
        '/commodity-prices/',
        queryParameters: {
          if (category != null) 'category': category,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (limit != null) 'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return CommodityPriceListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load commodity prices: $e');
    }
  }

  Future<CommodityPriceDetailResponse> getCommodityPriceDetail(
      String commodityId) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.get(
        '/commodity-prices/$commodityId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return CommodityPriceDetailResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load commodity detail: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.get(
        '/commodity-prices/categories/list',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return List<String>.from(response.data['categories']);
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
