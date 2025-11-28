import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  User? _currentUser;
  User? get currentUser => _currentUser;

  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Login - supports email
  Future<User> login(String email, String password) async {
    try {
      // 1. Login to get token
      final response = await _apiService.client.post(
        '/users/login',
        data: {
          'username': email, // OAuth2 expects 'username' field
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final token = response.data['access_token'];
      await _saveToken(token);

      // 2. Get user info
      return await _fetchCurrentUser();
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Đăng nhập thất bại');
      }
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  Future<User> _fetchCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('No token found');

      final response = await _apiService.client.get(
        '/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      _currentUser = User.fromJson(response.data);
      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to fetch user info: $e');
    }
  }

  // Register new user
  Future<User> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // ignore: unused_local_variable
      final response = await _apiService.client.post(
        '/users/register',
        data: {
          'email': email,
          'username': email.split('@')[0], // Generate username from email
          'password': password,
          'full_name': fullName,
          // 'phone_number': phoneNumber, // Backend DTO does not support phone_number yet
        },
      );

      // After register, login automatically
      return await login(email, password);
    } catch (e) {
      if (e is DioException) {
        // Check if it's a validation error
        if (e.response?.statusCode == 422) {
          throw Exception('Dữ liệu không hợp lệ: ${e.response?.data}');
        }
        throw Exception(e.response?.data['detail'] ?? 'Đăng ký thất bại');
      }
      throw Exception('Đăng ký thất bại: ${e.toString()}');
    }
  }

  // Login with Google
  Future<User> loginWithGoogle() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      _currentUser = User(
        id: '456',
        email: 'google.user@gmail.com',
        displayName: 'Google User',
        photoUrl: 'https://via.placeholder.com/150',
        createdAt: DateTime.now(),
      );

      return _currentUser!;
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: ${e.toString()}');
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Gửi email khôi phục thất bại: ${e.toString()}');
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock: some emails are already taken
      final takenEmails = ['test@example.com', 'admin@openagri.com'];
      return takenEmails.contains(email.toLowerCase());
    } catch (e) {
      return false;
    }
  }
}
