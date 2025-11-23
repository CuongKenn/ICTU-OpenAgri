import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commodity_price.dart';

class CommodityPriceService {
  static const String baseUrl = 'http://localhost:8000/api/v1/commodity-prices';

  Future<CommodityPriceListResponse> getCommodityPrices({
    String? category,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        if (category != null) 'category': category,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (limit != null) 'limit': limit.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return CommodityPriceListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load commodity prices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching commodity prices: $e');
    }
  }

  Future<CommodityPriceDetail> getCommodityPriceDetail(String commodityId) async {
    try {
      final uri = Uri.parse('$baseUrl/$commodityId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return CommodityPriceDetail.fromJson(jsonData);
      } else {
        throw Exception('Failed to load commodity detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching commodity detail: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/categories/list');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return List<String>.from(jsonData['categories'] as List);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
}

