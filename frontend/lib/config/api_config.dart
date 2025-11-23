import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class ApiConfig {
  static Environment get environment {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  static String get baseUrl {
    switch (environment) {
      case Environment.dev:
        return _getDevBaseUrl();
      case Environment.staging:
        return 'https://staging-api.openagri.com/api/v1';
      case Environment.prod:
        return 'https://api.openagri.com/api/v1';
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
