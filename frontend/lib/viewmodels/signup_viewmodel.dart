import 'package:flutter/material.dart';

class SignUpViewModel extends ChangeNotifier {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  // Validate full name
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập tên của bạn';
    }
    if (value.length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  // Validate email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  // Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    // Check for at least one letter and one number
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetter || !hasNumber) {
      return 'Mật khẩu phải có cả chữ và số';
    }
    return null;
  }

  // Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  // Sign up
  Future<void> signUp(BuildContext context) async {
    _errorMessage = null;
    
    // Validate all inputs
    final nameError = validateFullName(fullNameController.text);
    final emailError = validateEmail(emailController.text);
    final passwordError = validatePassword(passwordController.text);
    final confirmPasswordError = validateConfirmPassword(confirmPasswordController.text);
    
    if (nameError != null || emailError != null || 
        passwordError != null || confirmPasswordError != null) {
      _errorMessage = nameError ?? emailError ?? passwordError ?? confirmPasswordError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual sign up API call
      // Example:
      // final response = await authService.register(
      //   fullName: fullNameController.text,
      //   email: emailController.text,
      //   password: passwordController.text,
      // );
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // If successful
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to login or home
        Navigator.pop(context); // Go back to login screen
        // Or navigate to home:
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (_) => HomeScreen()),
        // );
      }
    } catch (e) {
      _errorMessage = 'Đăng ký thất bại. Email có thể đã được sử dụng.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Navigate to login screen
  void navigateToLogin(BuildContext context) {
    Navigator.pop(context);
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
