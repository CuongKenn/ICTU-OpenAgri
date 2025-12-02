import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/crop_field.dart';
import '../services/farm_service.dart';
import '../widgets/app_navigation_bar.dart';

class FieldMapScreen extends StatefulWidget {
  const FieldMapScreen({super.key});

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen> {
  final MapController _mapController = MapController();
  final FarmService _farmService = FarmService();
  List<CropField> fields = [];
  CropField? selectedField;
  List<LatLng> newFieldPoints = [];
  bool isDrawingMode = false;
  bool isLoading = false;

  // Form data for new field
  String newFieldName = '';
  String newFieldCropType = 'Lúa';
  double newFieldArea = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() => isLoading = true);
    try {
      final loadedFarms = await _farmService.getFarms();
      setState(() {
        fields = loadedFarms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _startDrawingMode() {
    setState(() {
      isDrawingMode = true;
      newFieldPoints.clear();
      selectedField = null;
    });
  }

  void _cancelDrawing() {
    setState(() {
      isDrawingMode = false;
      newFieldPoints.clear();
    });
  }

  void _addPointToField(LatLng point) {
    if (!isDrawingMode || newFieldPoints.length >= 4) return;

    setState(() {
      newFieldPoints.add(point);

      // Nếu đã có đủ 4 điểm, hiện form nhập thông tin
      if (newFieldPoints.length == 4) {
        _showFieldInfoDialog();
      }
    });
  }

  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Shoelace formula để tính diện tích polygon
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = (area.abs() / 2.0);

    // Convert to hectares (approximation: 1 degree ≈ 111km)
    area = area * 111 * 111 * 100; // Convert to hectares
    return area;
  }

  LatLng _calculateCenter(List<LatLng> points) {
    double lat = 0.0;
    double lng = 0.0;
    for (var point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final isMobile = width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: const AppNavigationBar(currentIndex: 1),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
      floatingActionButton: isMobile && !isDrawingMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FloatingActionButton(
                onPressed: _startDrawingMode,
                backgroundColor: const Color(0xFF0BDA50),
                elevation: 4,
                child: const Icon(Icons.draw, color: Colors.white, size: 24),
              ),
            )
          : !isMobile
          ? FloatingActionButton.extended(
              onPressed: _startDrawingMode,
              backgroundColor: const Color(0xFF0BDA50),
              icon: const Icon(Icons.draw, color: Colors.white),
              label: const Text(
                'Vẽ Vùng Trồng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý Vùng trồng',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111813),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${fields.length} vùng đang quản lý',
            style: const TextStyle(fontSize: 16, color: Color(0xFF608a6e)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                // LEFT LIST
                SizedBox(width: 340, child: _buildFieldList()),
                const SizedBox(width: 24),
                // RIGHT MAP
                Expanded(child: _buildMapSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Column(
          children: [
            // MAP SECTION - Full screen khi đang vẽ
            Expanded(flex: isDrawingMode ? 7 : 6, child: _buildMapSection()),
            // FIELD LIST - Ẩn khi đang vẽ
            if (!isDrawingMode)
              Expanded(flex: 4, child: _buildFieldList())
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chọn 4 điểm trên bản đồ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111813),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${newFieldPoints.length}/4 điểm đã chọn',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF608a6e),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _cancelDrawing,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Hủy'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    // Kết hợp existing fields và newFieldPoints để hiển thị
    List<Polygon> allPolygons = fields.map((field) {
      final isSelected = selectedField?.id == field.id;
      return Polygon(
        points: field.polygonPoints,
        color: _getCropColor(field.cropType).withValues(alpha: 0.4),
        borderColor: isSelected ? Colors.white : _getCropColor(field.cropType),
        borderStrokeWidth: isSelected ? 3 : 2,
      );
    }).toList();

    // Thêm polygon đang vẽ (nếu có ít nhất 2 điểm)
    if (isDrawingMode && newFieldPoints.length >= 2) {
      allPolygons.add(
        Polygon(
          points: newFieldPoints,
          color: const Color(0xFF0BDA50).withValues(alpha: 0.3),
          borderColor: const Color(0xFF0BDA50),
          borderStrokeWidth: 3,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDrawingMode ? 0 : 16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDrawingMode ? 0 : 16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(10.033333, 105.783333),
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                keepAlive: true,
                onTap: (tapPosition, latLng) {
                  if (isDrawingMode) {
                    _addPointToField(latLng);
                  } else {
                    setState(() => selectedField = null);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.agritech.app',
                ),
                PolygonLayer(polygons: allPolygons),
                MarkerLayer(
                  markers: [
                    // Markers cho existing fields
                    ...fields.map((field) {
                      return Marker(
                        point: field.center,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            if (!isDrawingMode) {
                              setState(() => selectedField = field);
                              _mapController.move(field.center, 16);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getCropColor(field.cropType),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getCropIcon(field.cropType),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Markers cho các điểm đang vẽ - Clean style
                    if (isDrawingMode)
                      ...newFieldPoints.asMap().entries.map((entry) {
                        return Marker(
                          point: entry.value,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0BDA50), width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ),
            // Zoom controls
            Positioned(
              bottom: isDrawingMode ? 100 : 16,
              right: 16,
              child: Column(
                children: [
                  _buildMapButton(Icons.add, () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildMapButton(Icons.remove, () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  }),
                  if (isDrawingMode && newFieldPoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildMapButton(Icons.undo, () {
                      setState(() {
                        if (newFieldPoints.isNotEmpty) {
                          newFieldPoints.removeLast();
                        }
                      });
                    }),
                  ],
                ],
              ),
            ),
            // Drawing mode indicator (top)
            if (isDrawingMode)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0BDA50),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chế độ vẽ vùng trồng',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chạm ${4 - newFieldPoints.length} điểm còn lại',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 24, color: color ?? const Color(0xFF4A5C52)),
        ),
      ),
    );
  }

  Widget _buildFieldList() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isMobile ? 24 : 16),
          bottom: Radius.circular(isMobile ? 0 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vùng trồng của bạn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111813),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fields.length} vùng đang quản lý',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF608a6e),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.eco,
                          size: 16,
                          color: Color(0xFF0BDA50),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${fields.where((f) => f.ndviValue >= 0.7).length} khỏe mạnh',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0BDA50),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: fields.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final field = fields[index];
                final isSelected = selectedField?.id == field.id;
                return InkWell(
                  onTap: () {
                    setState(() => selectedField = field);
                    _mapController.move(field.center, 16);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF0FDF4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0BDA50)
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getCropColor(
                              field.cropType,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCropIcon(field.cropType),
                            color: _getCropColor(field.cropType),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${field.area} ha • ${field.cropType}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF0BDA50),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFieldInfoDialog() {
    final nameController = TextEditingController();
    final calculatedArea = _calculateArea(newFieldPoints);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin Vùng trồng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF0BDA50)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vùng trồng đã được vẽ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Diện tích ước tính: ${calculatedArea.toStringAsFixed(2)} ha',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF608a6e),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên vùng trồng *',
                  hintText: 'VD: Vùng lúa A1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.terrain),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: newFieldCropType,
                decoration: const InputDecoration(
                  labelText: 'Loại cây trồng',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                items: const [
                  DropdownMenuItem(value: 'Lúa', child: Text('Lúa')),
                  DropdownMenuItem(
                    value: 'Cây ăn trái',
                    child: Text('Cây ăn trái'),
                  ),
                  DropdownMenuItem(
                    value: 'Cây công nghiệp',
                    child: Text('Cây công nghiệp'),
                  ),
                  DropdownMenuItem(value: 'Rau màu', child: Text('Rau màu')),
                ],
                onChanged: (v) => setState(() => newFieldCropType = v ?? 'Lúa'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelDrawing();
            },
            child: const Text('Hủy'),
          ),

          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập tên vùng trồng!'),
                  ),
                );
                return;
              }

              try {
                // Prepare data for API
                final farmData = {
                  'name': nameController.text,
                  'crop_type': newFieldCropType,
                  'area_size': calculatedArea,
                  'coordinates': newFieldPoints.map((p) => {
                    'lat': p.latitude,
                    'lng': p.longitude,
                  }).toList(),
                };

                // Call API
                final newField = await _farmService.createFarm(farmData);

                setState(() {
                  fields.add(newField);
                  selectedField = newField;
                  isDrawingMode = false;
                  newFieldPoints.clear();
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã thêm vùng trồng mới!'),
                      backgroundColor: Color(0xFF0BDA50),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi lưu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0BDA50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Color _getCropColor(String type) {
    if (type == 'Lúa') return const Color(0xFF10B981);
    if (type == 'Cây ăn trái') return const Color(0xFFF59E0B);
    return const Color(0xFF8B5CF6);
  }

  IconData _getCropIcon(String type) {
    if (type == 'Lúa') return Icons.grass;
    if (type == 'Cây ăn trái') return Icons.agriculture;
    return Icons.spa;
  }
}
