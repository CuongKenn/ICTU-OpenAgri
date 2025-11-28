import 'package:flutter/material.dart';

class DashboardStats {
  final int totalFields;
  final double totalArea;
  final double averageNDVI;
  final int activeAlerts;
  final double soilMoisture;
  final String weatherCondition;
  final double temperature;

  DashboardStats({
    required this.totalFields,
    required this.totalArea,
    required this.averageNDVI,
    required this.activeAlerts,
    required this.soilMoisture,
    required this.weatherCondition,
    required this.temperature,
  });

  static DashboardStats empty() {
    return DashboardStats(
      totalFields: 0,
      totalArea: 0.0,
      averageNDVI: 0.0,
      activeAlerts: 0,
      soilMoisture: 0.0,
      weatherCondition: '--',
      temperature: 0.0,
    );
  }

  static DashboardStats getMockData() {
    return DashboardStats(
      totalFields: 12,
      totalArea: 145.8,
      averageNDVI: 0.78,
      activeAlerts: 3,
      soilMoisture: 68.0,
      weatherCondition: 'Nắng',
      temperature: 28.5,
    );
  }
}

class FieldStatus {
  final String id;
  final String name;
  final String status; // 'healthy', 'warning', 'critical'
  final double ndvi;
  final double area;
  final String lastUpdate;

  FieldStatus({
    required this.id,
    required this.name,
    required this.status,
    required this.ndvi,
    required this.area,
    required this.lastUpdate,
  });

  static List<FieldStatus> getMockList() {
    return [
      FieldStatus(
        id: '1',
        name: 'Vùng trồng A1',
        status: 'healthy',
        ndvi: 0.82,
        area: 12.5,
        lastUpdate: '10/09/2024',
      ),
      FieldStatus(
        id: '2',
        name: 'Vùng trồng B2',
        status: 'healthy',
        ndvi: 0.75,
        area: 18.3,
        lastUpdate: '10/09/2024',
      ),
      FieldStatus(
        id: '3',
        name: 'Vùng trồng C3',
        status: 'warning',
        ndvi: 0.68,
        area: 9.8,
        lastUpdate: '10/09/2024',
      ),
      FieldStatus(
        id: '4',
        name: 'Vùng trồng D4',
        status: 'healthy',
        ndvi: 0.85,
        area: 15.2,
        lastUpdate: '09/09/2024',
      ),
      FieldStatus(
        id: '5',
        name: 'Vùng trồng E5',
        status: 'critical',
        ndvi: 0.52,
        area: 8.4,
        lastUpdate: '10/09/2024',
      ),
    ];
  }

  Color get statusColor {
    switch (status) {
      case 'healthy':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFFBBF24);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'healthy':
        return 'Tốt';
      case 'warning':
        return 'Cảnh báo';
      case 'critical':
        return 'Nguy hiểm';
      default:
        return 'Không rõ';
    }
  }
}

class ActivityLog {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String type; // 'info', 'warning', 'success'

  ActivityLog({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  static List<ActivityLog> getMockList() {
    final now = DateTime.now();
    return [
      ActivityLog(
        id: '1',
        title: 'Cập nhật dữ liệu vệ tinh',
        description: 'Dữ liệu NDVI mới đã được cập nhật cho tất cả vùng trồng',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: 'success',
      ),
      ActivityLog(
        id: '2',
        title: 'Cảnh báo độ ẩm đất thấp',
        description: 'Vùng trồng C3 có độ ẩm đất dưới ngưỡng khuyến nghị',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: 'warning',
      ),
      ActivityLog(
        id: '3',
        title: 'Hoàn thành phân tích',
        description: 'Phân tích sức khỏe cây trồng tháng 9 đã hoàn tất',
        timestamp: now.subtract(const Duration(days: 1)),
        type: 'info',
      ),
      ActivityLog(
        id: '4',
        title: 'Phát hiện sâu bệnh',
        description: 'Vùng trồng E5 phát hiện dấu hiệu sâu bệnh',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        type: 'warning',
      ),
    ];
  }

  Color get typeColor {
    switch (type) {
      case 'success':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFFBBF24);
      case 'info':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

class WeatherData {
  final String condition;
  final double temperature;
  final int humidity;
  final double rainfall;
  final String icon;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.icon,
  });

  static WeatherData getMockData() {
    return WeatherData(
      condition: 'Nắng',
      temperature: 28.5,
      humidity: 65,
      rainfall: 0.0,
      icon: '☀️',
    );
  }
}
