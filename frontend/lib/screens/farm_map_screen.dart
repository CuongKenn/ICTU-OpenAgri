// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../viewmodels/farm_map_viewmodel.dart';
import 'satellite_monitoring_screen.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({super.key});

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  final MapController _mapController = MapController();

  // Form data for new field (UI state)
  String newFieldCropType = 'Lúa';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<FarmMapViewModel>();
      viewModel.initData();
      viewModel.addListener(() {
        if (viewModel.isDrawingComplete) {
          _showFieldInfoDialog(context, viewModel);
          viewModel.resetDrawingComplete();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final isMobile = width <= 768;

    return Consumer<FarmMapViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F8F6),
          appBar: AppBar(
            title: const Text('Bản đồ nông trại'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: isDesktop
                ? _buildDesktopLayout(viewModel)
                : _buildMobileLayout(viewModel, isMobile),
          ),
          floatingActionButton: isMobile && !viewModel.isDrawingMode
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: FloatingActionButton(
                    onPressed: viewModel.startDrawingMode,
                    backgroundColor: const Color(0xFF0BDA50),
                    elevation: 4,
                    child:
                        const Icon(Icons.draw, color: Colors.white, size: 24),
                  ),
                )
              : !isMobile
                  ? FloatingActionButton.extended(
                      onPressed: viewModel.startDrawingMode,
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
      },
    );
  }

  Widget _buildDesktopLayout(FarmMapViewModel viewModel) {
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
            '${viewModel.fields.length} vùng đang quản lý',
            style: const TextStyle(fontSize: 16, color: Color(0xFF608a6e)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                // LEFT LIST
                SizedBox(width: 340, child: _buildFieldList(viewModel)),
                const SizedBox(width: 24),
                // RIGHT MAP
                Expanded(child: _buildMapSection(viewModel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(FarmMapViewModel viewModel, bool isMobile) {
    return Stack(
      children: [
        Column(
          children: [
            // MAP SECTION - Full screen khi đang vẽ
            Expanded(
                flex: viewModel.isDrawingMode ? 7 : 6,
                child: _buildMapSection(viewModel)),
            // FIELD LIST - Ẩn khi đang vẽ
            if (!viewModel.isDrawingMode)
              Expanded(flex: 4, child: _buildFieldList(viewModel))
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
                                '${viewModel.newFieldPoints.length}/4 điểm đã chọn',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF608a6e),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: viewModel.cancelDrawing,
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

  Widget _buildMapSection(FarmMapViewModel viewModel) {
    // Kết hợp existing fields và newFieldPoints để hiển thị
    final List<Polygon> allPolygons = viewModel.fields.map((field) {
      final isSelected = viewModel.selectedField?.id == field.id;
      return Polygon(
        points: field.polygonPoints,
        color: _getCropColor(field.cropType).withValues(alpha: 0.4),
        borderColor: isSelected ? Colors.white : _getCropColor(field.cropType),
        borderStrokeWidth: isSelected ? 3 : 2,
      );
    }).toList();

    // Thêm polygon đang vẽ (nếu có ít nhất 2 điểm)
    if (viewModel.isDrawingMode && viewModel.newFieldPoints.length >= 2) {
      allPolygons.add(
        Polygon(
          points: viewModel.newFieldPoints,
          color: const Color(0xFF0BDA50).withValues(alpha: 0.3),
          borderColor: const Color(0xFF0BDA50),
          borderStrokeWidth: 3,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(viewModel.isDrawingMode ? 0 : 16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(viewModel.isDrawingMode ? 0 : 16),
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
                  if (viewModel.isDrawingMode) {
                    viewModel.addPoint(latLng);
                  } else {
                    viewModel.selectField(null);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.agritech.app',
                ),
                PolygonLayer(polygons: allPolygons),
                MarkerLayer(
                  markers: [
                    // Markers cho existing fields
                    ...viewModel.fields.map((field) {
                      return Marker(
                        point: field.center,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            if (!viewModel.isDrawingMode) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SatelliteMonitoringScreen(
                                    initialFieldId: field.id,
                                  ),
                                ),
                              );
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
                    // Markers cho các điểm đang vẽ
                    if (viewModel.isDrawingMode)
                      ...viewModel.newFieldPoints.asMap().entries.map((entry) {
                        return Marker(
                          point: entry.value,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0BDA50),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    // Current Location Marker
                    if (viewModel.currentLocation != null)
                      Marker(
                        point: viewModel.currentLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Zoom controls
            Positioned(
              bottom: viewModel.isDrawingMode ? 100 : 16,
              right: 16,
              child: Column(
                children: [
                  // My Location Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMapButton(
                      Icons.my_location,
                      () {
                        if (viewModel.currentLocation != null) {
                          _mapController.move(viewModel.currentLocation!, 15);
                        }
                      },
                      color: viewModel.currentLocation != null
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
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
                  if (viewModel.isDrawingMode &&
                      viewModel.newFieldPoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildMapButton(Icons.undo, () {
                      // Undo logic should be in ViewModel
                      // viewModel.undoLastPoint();
                      // For now, we can just clear or implement undo in VM
                    }),
                  ],
                ],
              ),
            ),
            // Drawing mode indicator (top)
            if (viewModel.isDrawingMode)
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
                              'Chạm ${4 - viewModel.newFieldPoints.length} điểm còn lại',
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
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 28, color: color ?? Colors.black),
        ),
      ),
    );
  }

  Widget _buildFieldList(FarmMapViewModel viewModel) {
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
                        '${viewModel.fields.length} vùng đang quản lý',
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
                          '${viewModel.fields.where((f) => f.ndviValue >= 0.7).length} khỏe mạnh',
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
              itemCount: viewModel.fields.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final field = viewModel.fields[index];
                final isSelected = viewModel.selectedField?.id == field.id;
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SatelliteMonitoringScreen(
                          initialFieldId: field.id,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFF0FDF4) : Colors.white,
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

  void _showFieldInfoDialog(BuildContext context, FarmMapViewModel viewModel) {
    final nameController = TextEditingController();
    final calculatedArea = viewModel.calculateArea(viewModel.newFieldPoints);

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
              viewModel.cancelDrawing();
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập tên vùng trồng!'),
                  ),
                );
                return;
              }

              viewModel.saveNewField(
                nameController.text,
                newFieldCropType,
                calculatedArea,
              );

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã thêm vùng trồng mới!'),
                  backgroundColor: Color(0xFF0BDA50),
                ),
              );
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
