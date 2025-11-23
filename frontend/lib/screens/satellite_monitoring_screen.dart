import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/crop_field.dart';
import '../widgets/app_navigation_bar.dart';

class SatelliteMonitoringScreen extends StatefulWidget {
  const SatelliteMonitoringScreen({super.key});

  @override
  State<SatelliteMonitoringScreen> createState() =>
      _SatelliteMonitoringScreenState();
}

class _SatelliteMonitoringScreenState extends State<SatelliteMonitoringScreen> {
  final MapController _mapController = MapController();

  List<CropField> fields = [];
  CropField? selectedField;

  String mapMode = 'NDVI';
  String mapLayerType = 'Satellite';

  String activeControlTab = 'filter';
  DateTime selectedDate = DateTime(2024, 9);
  bool showCropType = true;
  bool showHealth = true;

  @override
  void initState() {
    super.initState();
    fields = CropField.getMockFields();
    selectedField = fields.first;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: const AppNavigationBar(currentIndex: 2),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ============ DESKTOP LAYOUT ============
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giám sát Vệ tinh Vùng trồng',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111813),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Phân tích sức khỏe cây trồng và độ ẩm đất dựa trên dữ liệu từ vệ tinh Sentinel-2 và Sentinel-1.',
            style: TextStyle(fontSize: 16, color: Color(0xFF608a6e)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    child: _buildSidebar(isMobile: false),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildMapSection()),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildSatelliteDataCard()),
                          const SizedBox(width: 32),
                          Expanded(flex: 6, child: _buildChartCard()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ MOBILE LAYOUT (RE-DESIGNED) ============
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 1. MAP SECTION (Top) - Chiếm 50% màn hình
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              _buildMapSection(isMobile: true),
              // Nút mở bảng điều khiển đè lên map (góc dưới phải)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _showControlPanelBottomSheet(),
                  backgroundColor: const Color(0xFF0BDA50),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // 2. INFO SECTION - Chiếm 50% màn hình
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F8F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Thông số Vệ tinh',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111813),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSatelliteDataCard(),
                  const SizedBox(height: 20),
                  _buildChartCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showControlPanelBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bảng điều khiển',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111813),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Content - scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: _buildSidebar(isMobile: true),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============ MAP SECTION ============
  Widget _buildMapSection({bool isMobile = false}) {
    return ClipRRect(
      borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  selectedField?.center ?? const LatLng(10.033333, 105.783333),
              initialZoom: 15.5,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapTileUrl(),
                userAgentPackageName: 'com.agritech.app',
              ),
              PolygonLayer(
                polygons: fields.map((field) {
                  final isSelected = selectedField?.id == field.id;
                  Color overlayColor = mapMode == 'NDVI'
                      ? _getNDVIColor(field.ndviValue)
                      : _getMoistureColor(field.ndviValue * 100);

                  return Polygon(
                    points: field.polygonPoints,
                    color: overlayColor.withValues(alpha: 0.6),
                    borderColor: isSelected ? Colors.white : overlayColor,
                    borderStrokeWidth: isSelected ? 3 : 2,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: fields.map((field) {
                  return Marker(
                    point: field.center,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => setState(() => selectedField = field),
                      child: Container(
                        decoration: BoxDecoration(
                          color: mapMode == 'NDVI'
                              ? _getNDVIColor(field.ndviValue)
                              : _getMoistureColor(field.ndviValue * 100),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Mode Selector (Centered Top)
          Positioned(
            top: 16,
            left: 16,
            right: isMobile ? 70 : 16, // Tránh nút filter trên mobile
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeChip('NDVI', 'NDVI', Icons.eco),
                    _buildModeChip('Độ ẩm', 'Moisture', Icons.water_drop),
                  ],
                ),
              ),
            ),
          ),

          // Zoom Controls
          Positioned(
            bottom: isMobile ? 40 : 24,
            right: 16,
            child: Column(
              children: [
                _buildMapButton(Icons.add, () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                }),
                const SizedBox(height: 12),
                _buildMapButton(Icons.remove, () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ SIDEBAR (CONTROL PANEL) ============
  Widget _buildSidebar({required bool isMobile}) {
    // Trên mobile, không cần container border vì đã nằm trong bottom sheet
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildControlTabs(),
          const SizedBox(height: 20),
          if (activeControlTab == 'filter') _buildFilterContent(),
          if (activeControlTab == 'layers') _buildLayersContent(),
          if (activeControlTab == 'legend') _buildLegendContent(),
        ],
      );
    }

    // Desktop style
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F5F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bảng điều khiển',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tùy chỉnh hiển thị bản đồ',
            style: TextStyle(fontSize: 14, color: Color(0xFF608a6e)),
          ),
          const SizedBox(height: 24),
          _buildControlTabs(),
          const SizedBox(height: 24),
          if (activeControlTab == 'filter') _buildFilterContent(),
          if (activeControlTab == 'layers') _buildLayersContent(),
          if (activeControlTab == 'legend') _buildLegendContent(),
        ],
      ),
    );
  }

  // ============ CARDS & COMPONENTS ============

  Widget _buildSatelliteDataCard() {
    if (selectedField == null) return const SizedBox();

    final soilMoisture = (selectedField!.ndviValue * 100).toDouble();
    final ndvi = selectedField!.ndviValue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0BDA50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.satellite_alt,
                  color: Color(0xFF0BDA50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedField!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${selectedField!.area} ha • ${selectedField!.cropType}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF608a6e),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // Sentinel-2
          _buildDataRow(
            icon: Icons.wb_sunny_outlined,
            title: 'Sentinel-2 (Quang học)',
            value: ndvi.toStringAsFixed(2),
            unit: 'NDVI',
            status: 'Sức khỏe tốt',
            statusColor: _getNDVIColor(ndvi),
          ),
          const SizedBox(height: 20),
          // Sentinel-1
          _buildDataRow(
            icon: Icons.radar_outlined,
            title: 'Sentinel-1 (Radar)',
            value: soilMoisture.toStringAsFixed(0),
            unit: '%',
            status: soilMoisture < 40 ? 'Cần tưới' : 'Đủ ẩm',
            statusColor: soilMoisture < 40 ? Colors.orange : Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Text(
                mapMode == 'NDVI' ? 'Biểu đồ NDVI' : 'Biểu đồ Độ ẩm',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.show_chart, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Center(
              child: Image.network(
                mapMode == 'NDVI'
                    ? 'https://quickchart.io/chart?c={type:%27line%27,data:{labels:[%27T1%27,%27T8%27,%27T15%27,%27T22%27,%27T30%27],datasets:[{label:%27NDVI%27,data:[0.3,0.5,0.6,0.75,0.82],borderColor:%27rgb(16,185,129)%27,backgroundColor:%27rgba(16,185,129,0.1)%27,fill:true,tension:0.4}]},options:{plugins:{legend:{display:false}},scales:{x:{grid:{display:false}},y:{grid:{display:false}}}}}'
                    : 'https://quickchart.io/chart?c={type:%27line%27,data:{labels:[%27T1%27,%27T8%27,%27T15%27,%27T22%27,%27T30%27],datasets:[{label:%27Moisture%27,data:[30,45,55,70,82],borderColor:%27rgb(59,130,246)%27,backgroundColor:%27rgba(59,130,246,0.1)%27,fill:true,tension:0.4}]},options:{plugins:{legend:{display:false}},scales:{x:{grid:{display:false}},y:{grid:{display:false}}}}}',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods

  Widget _buildControlTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _buildTab('Bộ lọc', 'filter', Icons.filter_alt),
          _buildTab('Lớp bản đồ', 'layers', Icons.layers),
          _buildTab('Chú giải', 'legend', Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String value, IconData icon) {
    final isActive = activeControlTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeControlTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0BDA50) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF0BDA50)
                  : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0BDA50).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, String value, IconData icon) {
    final isActive = mapMode == value;
    return GestureDetector(
      onTap: () => setState(() => mapMode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF111813) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF608a6e),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF608a6e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMapTileUrl() {
    if (mapLayerType == 'Street') {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    if (mapLayerType == 'Terrain') {
      return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    }
    return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  }

  Color _getNDVIColor(double value) {
    if (value >= 0.7) return const Color(0xFF10B981);
    if (value >= 0.5) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  Color _getMoistureColor(double percent) {
    if (percent >= 60) return const Color(0xFF1E3A8A);
    if (percent >= 40) return const Color(0xFF3B82F6);
    return const Color(0xFF93C5FD);
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF111813)),
      ),
    );
  }

  // ... [Control Panel Helpers] ...
  Widget _buildFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterItem('Thời gian', 'Tháng 9/2024', Icons.calendar_today),
        const SizedBox(height: 16),
        _buildFilterItem('Lớp dữ liệu', 'Tất cả', Icons.layers),
      ],
    );
  }

  Widget _buildFilterItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0BDA50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111813),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  Widget _buildLayersContent() {
    return Column(
      children: [
        _buildMapLayerOption('Satellite', 'Vệ tinh', Icons.satellite_alt),
        _buildMapLayerOption('Street', 'Đường phố', Icons.map),
        _buildMapLayerOption('Terrain', 'Địa hình', Icons.terrain),
      ],
    );
  }

  Widget _buildMapLayerOption(String type, String label, IconData icon) {
    final isSelected = mapLayerType == type;
    return GestureDetector(
      onTap: () => setState(() => mapLayerType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0BDA50)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0BDA50) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF0BDA50) : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0BDA50)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendContent() {
    return Column(
      children: [
        _buildLegendRow(const Color(0xFF10B981), 'Tốt (0.7 - 1.0)'),
        _buildLegendRow(const Color(0xFFFBBF24), 'Trung bình (0.5 - 0.7)'),
        _buildLegendRow(const Color(0xFFEF4444), 'Yếu (< 0.5)'),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
