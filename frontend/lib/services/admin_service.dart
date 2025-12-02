import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/admin_user.dart';
import '../models/api_models.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;

  late Dio _dio;

  AdminService._internal() {
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

  /// Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Get list of users with pagination and optional search
  Future<AdminUserListResponse> getUsers({
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '/admin/users',
        queryParameters: queryParams,
      );

      return AdminUserListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  /// Get user statistics
  Future<AdminUserStats> getUserStats() async {
    try {
      final response = await _dio.get('/admin/users/stats');
      return AdminUserStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load user statistics: $e');
    }
  }

  /// Get user details by ID
  Future<AdminUser> getUserDetail(int userId) async {
    try {
      final response = await _dio.get('/admin/users/$userId');
      return AdminUser.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load user details: $e');
    }
  }

  /// Delete user by ID
  Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('/admin/users/$userId');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Update user status (active/inactive)
  Future<AdminUser> updateUserStatus(int userId, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/admin/users/$userId/status',
        data: {'is_active': isActive},
      );
      return AdminUser.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Get list of farms with pagination
  Future<List<AdminFarmAreaResponseDTO>> getAllFarms({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/farms',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      return (response.data as List)
          .map((e) => AdminFarmAreaResponseDTO.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load farms: $e');
    }
  }
}
