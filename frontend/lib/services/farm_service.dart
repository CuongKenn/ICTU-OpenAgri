import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/crop_field.dart';

class FarmService {
  static final FarmService _instance = FarmService._internal();
  factory FarmService() => _instance;

  late Dio _dio;

  FarmService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<List<CropField>> getFarms() async {
    try {
      final response = await _dio.get('/farms/');
      final List<dynamic> data = response.data;
      return data.map((json) => CropField.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load farms: $e');
    }
  }

  Future<CropField> createFarm(Map<String, dynamic> farmData) async {
    try {
      final response = await _dio.post('/farms/', data: farmData);
      return CropField.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create farm: $e');
    }
  }
}
