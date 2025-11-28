import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../models/api_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WeatherService {
  // Singleton pattern
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

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
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Search location using Backend
  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.length < 3) return [];

    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.get(
        '/weather/search',
        queryParameters: {
          'query': query,
          'limit': 5,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final dto = LocationSearchResponseDTO.fromJson(response.data);

      return dto.results.map((item) {
        return {
          'name': item.name,
          'city': item.state ?? item.country,
          'country': item.country,
          'lat': item.latitude,
          'lon': item.longitude,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get weather data from Backend
  Future<Map<String, dynamic>> getWeatherData(double lat, double lon) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.client.get(
        '/weather/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'hours_ahead': 168,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final dto = ForecastResponseDTO.fromJson(response.data);
      return _transformBackendData(dto);
    } catch (e) {
      // Return mock data if API fails
      return _getMockWeatherData();
    }
  }

  Map<String, dynamic> _transformBackendData(ForecastResponseDTO dto) {
    final current = {
      'temperature_2m': dto.current.temperature2m,
      'relative_humidity_2m': dto.current.relativeHumidity2m,
      'weather_code': dto.current.weatherCode,
      'wind_speed_10m': dto.current.windSpeed10m,
      'precipitation': dto.current.precipitation,
      'is_day': dto.current.isDay,
    };

    final hourlyList = dto.hourly;

    // Transform hourly list to column-oriented map for UI
    final hourly = {
      'time': hourlyList.map((e) => e.time).toList(),
      'temperature_2m': hourlyList.map((e) => e.temperature2m).toList(),
      'relative_humidity_2m':
          hourlyList.map((e) => e.relativeHumidity2m).toList(),
      'weather_code': hourlyList.map((e) => e.weatherCode).toList(),
      'wind_speed_10m': hourlyList.map((e) => e.windSpeed10m).toList(),
      'precipitation_probability':
          hourlyList.map((e) => (e.precipitation > 0 ? 60 : 0)).toList(),
    };

    // Generate daily data from hourly (simplified aggregation)
    final daily = _generateDailyFromHourly(hourlyList);

    return {
      'current': current,
      'hourly': hourly,
      'daily': daily,
    };
  }

  Map<String, dynamic> _generateDailyFromHourly(
      List<HourlyWeatherDTO> hourlyList) {
    final List<String> times = [];
    final List<double> maxTemps = [];
    final List<double> minTemps = [];
    final List<int> codes = [];
    final List<int> probs = [];

    // Group by day
    final Map<String, List<HourlyWeatherDTO>> days = {};
    for (var item in hourlyList) {
      final timeStr = item.time;
      final dateStr = timeStr.split('T')[0]; // Assumes ISO format
      if (!days.containsKey(dateStr)) {
        days[dateStr] = [];
      }
      days[dateStr]!.add(item);
    }

    // Process each day
    days.forEach((date, items) {
      if (times.length >= 7) return;

      times.add(date);

      // Calculate max/min temp
      double maxT = -100;
      double minT = 100;
      int maxProb = 0;
      final Map<int, int> codeCounts = {};

      for (var item in items) {
        final t = item.temperature2m;
        if (t > maxT) maxT = t;
        if (t < minT) minT = t;

        final p = item.precipitation;
        if (p > 0) maxProb = 60; // Simplified

        final c = item.weatherCode;
        codeCounts[c] = (codeCounts[c] ?? 0) + 1;
      }

      maxTemps.add(maxT);
      minTemps.add(minT);
      probs.add(maxProb);

      // Most frequent weather code
      int mostFrequentCode = 0;
      int maxCount = 0;
      codeCounts.forEach((code, count) {
        if (count > maxCount) {
          maxCount = count;
          mostFrequentCode = code;
        }
      });
      codes.add(mostFrequentCode);
    });

    return {
      'time': times,
      'temperature_2m_max': maxTemps,
      'temperature_2m_min': minTemps,
      'weather_code': codes,
      'precipitation_probability_max': probs,
    };
  }

  // Helper to map WMO weather codes to description and icon
  Map<String, dynamic> getWeatherInfo(int code) {
    // WMO Weather interpretation codes (WW)
    // https://open-meteo.com/en/docs
    switch (code) {
      case 0:
        return {'desc': 'Trời quang', 'icon': 'clear_day'};
      case 1:
        return {'desc': 'Chủ yếu là nắng', 'icon': 'partly_cloudy_day'};
      case 2:
        return {'desc': 'Có mây', 'icon': 'partly_cloudy_day'};
      case 3:
        return {'desc': 'Nhiều mây', 'icon': 'cloudy'};
      case 45:
      case 48:
        return {'desc': 'Sương mù', 'icon': 'foggy'};
      case 51:
      case 53:
      case 55:
        return {'desc': 'Mưa phùn', 'icon': 'rainy_light'};
      case 61:
      case 63:
      case 65:
        return {'desc': 'Mưa', 'icon': 'rainy'};
      case 80:
      case 81:
      case 82:
        return {'desc': 'Mưa rào', 'icon': 'rainy_heavy'};
      case 95:
      case 96:
      case 99:
        return {'desc': 'Dông', 'icon': 'thunderstorm'};
      default:
        return {'desc': 'Không xác định', 'icon': 'cloud'};
    }
  }

  Map<String, dynamic> _getMockWeatherData() {
    final now = DateTime.now();
    final hourlyTimes =
        List.generate(24, (i) => now.add(Duration(hours: i)).toIso8601String());
    final dailyTimes =
        List.generate(7, (i) => now.add(Duration(days: i)).toIso8601String());

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
      "hourly": {
        "time": hourlyTimes,
        "temperature_2m": List.filled(24, 30.0),
        "relative_humidity_2m": List.filled(24, 70),
        "weather_code": List.filled(24, 1),
        "wind_speed_10m": List.filled(24, 10.0),
        "precipitation_probability": List.filled(24, 0),
      },
      "daily": {
        "time": dailyTimes,
        "temperature_2m_max": List.filled(7, 35.0),
        "temperature_2m_min": List.filled(7, 25.0),
        "weather_code": List.filled(7, 1),
        "precipitation_probability_max": List.filled(7, 20),
      }
    };
  }
}
