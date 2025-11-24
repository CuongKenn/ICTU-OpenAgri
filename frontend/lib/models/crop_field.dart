import 'package:latlong2/latlong.dart';

class CropField {
  final String id;
  final String name;
  final String cropType;
  final double area; // in hectares
  final double ndviValue;
  final String trendDirection; // 'up', 'down', 'stable'
  final DateTime lastUpdated;
  final List<NDVIDataPoint> ndviHistory;
  final String imageUrl;
  final List<LatLng> polygonPoints; // Real coordinates for the field
  final LatLng center;

  CropField({
    required this.id,
    required this.name,
    required this.cropType,
    required this.area,
    required this.ndviValue,
    required this.trendDirection,
    required this.lastUpdated,
    required this.ndviHistory,
    required this.imageUrl,
    required this.polygonPoints,
    required this.center,
  });

  // Mock data for demonstration (Located in Vietnam, Mekong Delta example)
  static List<CropField> getMockFields() {
    return [
      CropField(
        id: '1',
        name: 'Vùng trồng A1 (Lúa ST25)',
        cropType: 'Lúa',
        area: 12.5,
        ndviValue: 0.82,
        trendDirection: 'up',
        lastUpdated: DateTime(2024, 9, 10),
        ndviHistory: NDVIDataPoint.getMockData(),
        imageUrl: '',
        center: const LatLng(10.033333, 105.783333), // Can Tho approx
        polygonPoints: [
          const LatLng(10.033333, 105.783333),
          const LatLng(10.034333, 105.783333),
          const LatLng(10.034333, 105.784333),
          const LatLng(10.033333, 105.784333),
        ],
      ),
      CropField(
        id: '2',
        name: 'Vườn Xoài Cát Hòa Lộc',
        cropType: 'Cây ăn trái',
        area: 18.3,
        ndviValue: 0.75,
        trendDirection: 'stable',
        lastUpdated: DateTime(2024, 9, 10),
        ndviHistory: NDVIDataPoint.getMockData(offset: -0.05),
        imageUrl: '',
        center: const LatLng(10.035333, 105.785333),
        polygonPoints: [
          const LatLng(10.035333, 105.785333),
          const LatLng(10.036333, 105.785333),
          const LatLng(10.036333, 105.786333),
          const LatLng(10.035333, 105.786333),
        ],
      ),
      CropField(
        id: '3',
        name: 'Khu Cà phê Robusta',
        cropType: 'Cây công nghiệp',
        area: 9.8,
        ndviValue: 0.68,
        trendDirection: 'down',
        lastUpdated: DateTime(2024, 9, 10),
        ndviHistory: NDVIDataPoint.getMockData(offset: -0.12),
        imageUrl: '',
        center: const LatLng(10.031333, 105.781333),
        polygonPoints: [
          const LatLng(10.031333, 105.781333),
          const LatLng(10.032333, 105.781333),
          const LatLng(10.032333, 105.782333),
          const LatLng(10.031333, 105.782333),
        ],
      ),
    ];
  }

  String get cropTypeColorHex {
    switch (cropType) {
      case 'Lúa':
        return '#34D399';
      case 'Cây ăn trái':
        return '#FBBF24';
      case 'Cây công nghiệp':
        return '#A78BFA';
      default:
        return '#0BDA50';
    }
  }
}

class NDVIDataPoint {
  final DateTime date;
  final double value;

  NDVIDataPoint({required this.date, required this.value});

  static List<NDVIDataPoint> getMockData({double offset = 0}) {
    final now = DateTime.now();
    return List.generate(30, (index) {
      return NDVIDataPoint(
        date: now.subtract(Duration(days: 29 - index)),
        value: (0.6 + (index / 30) * 0.3 + offset).clamp(0.0, 1.0),
      );
    });
  }
}
