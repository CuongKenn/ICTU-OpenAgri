import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  // Singleton pattern
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Open-Meteo API base URL
  static const String _openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  
  // Photon API base URL
  static const String _photonBaseUrl = 'https://photon.komoot.io/api';

  // Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  // Search location using Photon
  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.length < 3) return [];
    
    try {
      final response = await http.get(Uri.parse('$_photonBaseUrl/?q=$query&limit=5'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        return features.map((feature) {
          final props = feature['properties'];
          final geometry = feature['geometry'];
          final coords = geometry['coordinates'];
          
          return {
            'name': props['name'] ?? '',
            'city': props['city'] ?? props['state'] ?? props['country'] ?? '',
            'country': props['country'] ?? '',
            'lat': coords[1],
            'lon': coords[0],
          };
        }).toList();
      } else {
        throw Exception('Failed to load location data');
      }
    } catch (e) {
      print('Error searching location: $e');
      return [];
    }
  }

  // Get weather data from Open-Meteo
  Future<Map<String, dynamic>> getWeatherData(double lat, double lon) async {
    try {
      final url = '$_openMeteoBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,weather_code,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max&timezone=auto';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      // Return mock data if API fails
      return _getMockWeatherData();
    }
  }

  // Helper to map WMO weather codes to description and icon
  Map<String, dynamic> getWeatherInfo(int code) {
    // WMO Weather interpretation codes (WW)
    // https://open-meteo.com/en/docs
    switch (code) {
      case 0: return {'desc': 'Trời quang', 'icon': 'clear_day'};
      case 1: return {'desc': 'Chủ yếu là nắng', 'icon': 'partly_cloudy_day'};
      case 2: return {'desc': 'Có mây', 'icon': 'partly_cloudy_day'};
      case 3: return {'desc': 'Nhiều mây', 'icon': 'cloudy'};
      case 45: 
      case 48: return {'desc': 'Sương mù', 'icon': 'foggy'};
      case 51: 
      case 53: 
      case 55: return {'desc': 'Mưa phùn', 'icon': 'rainy_light'};
      case 61: 
      case 63: 
      case 65: return {'desc': 'Mưa', 'icon': 'rainy'};
      case 80: 
      case 81: 
      case 82: return {'desc': 'Mưa rào', 'icon': 'rainy_heavy'};
      case 95: 
      case 96: 
      case 99: return {'desc': 'Dông', 'icon': 'thunderstorm'};
      default: return {'desc': 'Không xác định', 'icon': 'cloud'};
    }
  }

  Map<String, dynamic> _getMockWeatherData() {
    return {
      "current": {
        "temperature_2m": 32.0,
        "relative_humidity_2m": 75,
        "apparent_temperature": 35.0,
        "is_day": 1,
        "precipitation": 0.0,
        "rain": 0.0,
        "weather_code": 1,
        "wind_speed_10m": 15.0
      },
      // ... minimal mock structure if needed
    };
  }
}


