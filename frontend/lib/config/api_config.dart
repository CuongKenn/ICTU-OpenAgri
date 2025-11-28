import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class ApiConfig {
  static Environment get environment {
    // 1. Ưu tiên lấy từ tham số dòng lệnh --dart-define=ENV=...
    const env = String.fromEnvironment('ENV');
    if (env.isNotEmpty) {
      switch (env) {
        case 'prod':
          return Environment.prod;
        case 'staging':
          return Environment.staging;
        default:
          return Environment.dev;
      }
    }

    // 2. Nếu không có tham số, tự động check chế độ build
    if (kReleaseMode) {
      return Environment.prod;
    }

    return Environment.dev;
  }

  static String get baseUrl {
    switch (environment) {
      case Environment.dev:
        return _getDevBaseUrl();
      case Environment.staging:
        return 'https://staging-api.openagri.com/api/v1';
      case Environment.prod:
        return 'https://api.yoursite.com/api/v1';
    }
  }

  static String _getDevBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api/v1';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8000/api/v1';
      default:
        return 'http://localhost:8000/api/v1';
    }
  }

  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
