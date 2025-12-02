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

  factory CropField.fromJson(Map<String, dynamic> json) {
    // Parse coordinates
    List<LatLng> points = [];
    if (json['coordinates'] != null) {
      points = (json['coordinates'] as List).map((coord) {
        return LatLng(coord['lat'], coord['lng']);
      }).toList();
    }

    // Calculate center
    double lat = 0.0;
    double lng = 0.0;
    if (points.isNotEmpty) {
      for (var point in points) {
        lat += point.latitude;
        lng += point.longitude;
      }
      lat /= points.length;
      lng /= points.length;
    }

    return CropField(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      cropType: json['crop_type'] ?? 'Lúa',
      area: (json['area_size'] ?? 0.0).toDouble(),
      ndviValue: 0.5, // Default or fetch from separate endpoint if needed
      trendDirection: 'stable',
      lastUpdated: DateTime.now(),
      ndviHistory: [], // Fetch separately if needed
      imageUrl: '',
      polygonPoints: points,
      center: LatLng(lat, lng),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'crop_type': cropType,
      'area_size': area,
      'coordinates': polygonPoints.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList(),
    };
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
}
