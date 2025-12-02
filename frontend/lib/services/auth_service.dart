import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ignore: unused_field
  final ApiService _apiService = ApiService();
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Login - supports email, phone number, or username
  Future<User> login(String emailOrPhoneOrUsername, String password) async {
    try {
      final response = await _apiService.post('/users/login', data: {
        'username': emailOrPhoneOrUsername,
        'password': password,
      });

      // Store access token
      final token = response.data['access_token'];
      await _apiService.setAuthToken(token);

      // Get user info
      final userInfoResponse = await _apiService.get('/users/me');
      _currentUser = User.fromJson(userInfoResponse.data);

      return _currentUser!;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
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
      // Example API call:
      // final response = await _apiService.post('/auth/register', data: {
      //   'full_name': fullName,
      //   'email': email,
      //   'phone_number': phoneNumber,
      //   'password': password,
      // });
      // _currentUser = User.fromJson(response.data);

      await Future.delayed(const Duration(seconds: 2));

      // Check if email already exists (mock)
      // In real app, backend will handle this

      _currentUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        displayName: fullName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );

      return _currentUser!;
    } catch (e) {
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

  // Logout
  Future<void> logout() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = null;
    } catch (e) {
      throw Exception('Đăng xuất thất bại: ${e.toString()}');
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