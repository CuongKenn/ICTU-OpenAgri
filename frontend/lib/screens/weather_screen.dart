import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../services/weather_service.dart';
import '../widgets/app_navigation_bar.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final MapController _mapController = MapController();
  
  // State
  bool _isLoading = true;
  String _locationName = "Đang tải...";
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Default location (Hanoi)
  LatLng _currentLocation = const LatLng(21.0285, 105.8542);
  String _forecastTab = 'hourly'; // hourly, daily, weekly

  @override
  void initState() {
    super.initState();
    _initWeather();
  }

  Future<void> _initWeather() async {
    setState(() => _isLoading = true);
    try {
      final position = await _weatherService.getCurrentLocation();
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationName = "Vị trí hiện tại"; // Will update with reverse geocoding if available or just generic
      
      await _fetchWeather(_currentLocation.latitude, _currentLocation.longitude);
    } catch (e) {
      print('Error initializing weather: $e');
      // Fallback to default location
      await _fetchWeather(_currentLocation.latitude, _currentLocation.longitude);
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final data = await _weatherService.getWeatherData(lat, lon);
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
      
      // Move map
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _mapController.move(LatLng(lat, lon), 13);
      });
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu thời tiết: $e')),
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    final results = await _weatherService.searchLocation(query);
    setState(() {
      _searchResults = results;
      _showSearchResults = true;
    });
  }

  void _selectLocation(Map<String, dynamic> location) {
    final lat = location['lat'];
    final lon = location['lon'];
    final name = location['name'];
    
    setState(() {
      _currentLocation = LatLng(lat, lon);
      _locationName = name;
      _showSearchResults = false;
      _searchController.text = name;
      _searchResults = [];
      _isLoading = true;
    });
    
    _fetchWeather(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: const AppNavigationBar(currentIndex: 2),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0BDA50)))
          : SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          if (_weatherData != null) ...[
                            _buildCurrentWeatherCard(),
                            const SizedBox(height: 24),
                            _buildDetailsGrid(),
                            const SizedBox(height: 24),
                            _buildForecastSection(),
                            const SizedBox(height: 24),
                            _buildMapSection(),
                            const SizedBox(height: 24),
                            _buildAdviceSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_showSearchResults)
                    Positioned(
                      top: 80,
                      left: 24,
                      right: 24,
                      child: Card(
                        elevation: 4,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                title: Text(result['name']),
                                subtitle: Text('${result['city']}, ${result['country']}'),
                                onTap: () => _selectLocation(result),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Expanded(
              child: Text(
                'Dự Báo Thời Tiết',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111813),
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Text(
          'Thông tin thời tiết nông nghiệp chi tiết và chính xác',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF61896F),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _searchLocation,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm địa điểm...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'Khu vực 1',
                  icon: const Icon(Icons.expand_more, color: Colors.grey),
                  items: ['Khu vực 1', 'Khu vực 2', 'Khu vực 3']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentWeatherCard() {
    final current = _weatherData!['current'];
    final weatherCode = current['weather_code'];
    final weatherInfo = _weatherService.getWeatherInfo(weatherCode);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd/MM/yyyy - HH:mm', 'vi').format(now);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _locationName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111813),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _getWeatherIcon(weatherInfo['icon'], 64),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${current['temperature_2m']}°C',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111813),
                    ),
                  ),
                  Text(
                    weatherInfo['desc'],
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF61896F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    final current = _weatherData!['current'];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildDetailItem(Icons.thermostat, 'Cảm giác như', '${current['apparent_temperature']}°C', Colors.green),
        _buildDetailItem(Icons.water_drop, 'Độ ẩm', '${current['relative_humidity_2m']}%', Colors.blue),
        _buildDetailItem(Icons.air, 'Gió', '${current['wind_speed_10m']} km/h', Colors.grey),
        _buildDetailItem(Icons.umbrella, 'Khả năng mưa', '${current['precipitation'] ?? 0}%', Colors.purple),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111813),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dự báo chi tiết',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111813),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildTabButton('hourly', 'Hàng giờ'),
                    _buildTabButton('daily', 'Hàng ngày'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: _forecastTab == 'hourly' ? _buildHourlyForecast() : _buildDailyForecast(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String id, String label) {
    final isSelected = _forecastTab == id;
    return GestureDetector(
      onTap: () => setState(() => _forecastTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF111813) : const Color(0xFF61896F),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    final hourly = _weatherData!['hourly'];
    final times = hourly['time'] as List;
    final temps = hourly['temperature_2m'] as List;
    final codes = hourly['weather_code'] as List;
    final probs = hourly['precipitation_probability'] as List;
    
    // Get next 24 hours starting from current hour
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Find index of current hour (simplified)
    int startIndex = 0;
    for(int i=0; i<times.length; i++) {
      if(DateTime.parse(times[i]).hour == currentHour) {
        startIndex = i;
        break;
      }
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 24, // Show next 24 hours
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final i = startIndex + index;
        if(i >= times.length) return const SizedBox();
        
        final time = DateTime.parse(times[i]);
        final temp = temps[i];
        final code = codes[i];
        final prob = probs[i];
        final weatherInfo = _weatherService.getWeatherInfo(code);

        return Container(
          width: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '${time.hour}:00',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              _getWeatherIcon(weatherInfo['icon'], 32),
              Text(
                '$temp°',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 12, color: Colors.blue),
                  Text(
                    '$prob%',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDailyForecast() {
    final daily = _weatherData!['daily'];
    final times = daily['time'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;
    final codes = daily['weather_code'] as List;
    final probs = daily['precipitation_probability_max'] as List;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: times.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final time = DateTime.parse(times[index]);
        final maxTemp = maxTemps[index];
        final minTemp = minTemps[index];
        final code = codes[index];
        final prob = probs[index];
        final weatherInfo = _weatherService.getWeatherInfo(code);
        
        final dayName = index == 0 ? 'Hôm nay' : DateFormat('E', 'vi').format(time);

        return Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                dayName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              _getWeatherIcon(weatherInfo['icon'], 32),
              Text(
                '$maxTemp° / $minTemp°',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 12, color: Colors.blue),
                  Text(
                    '$prob%',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.openagri.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF0BDA50),
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF13EC5B), Color(0xFF0BDA50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb, color: Color(0xFF0BDA50), size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lời khuyên nông vụ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hôm nay độ ẩm cao, hãy chú ý thoát nước cho cây trồng để tránh ngập úng.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(String iconName, double size) {
    IconData iconData;
    Color color = Colors.orange;
    
    switch (iconName) {
      case 'clear_day':
        iconData = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case 'partly_cloudy_day':
        iconData = Icons.wb_cloudy;
        color = Colors.orangeAccent;
        break;
      case 'cloudy':
        iconData = Icons.cloud;
        color = Colors.grey;
        break;
      case 'rainy':
      case 'rainy_heavy':
        iconData = Icons.grain;
        color = Colors.blue;
        break;
      case 'rainy_light':
        iconData = Icons.water_drop_outlined;
        color = Colors.lightBlue;
        break;
      case 'thunderstorm':
        iconData = Icons.flash_on;
        color = Colors.deepPurple;
        break;
      case 'foggy':
        iconData = Icons.blur_on;
        color = Colors.blueGrey;
        break;
      default:
        iconData = Icons.wb_sunny;
    }
    
    return Icon(iconData, size: size, color: color);
  }
}

