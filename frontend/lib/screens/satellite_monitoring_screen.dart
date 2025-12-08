// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../viewmodels/pest_forecast_viewmodel.dart';
import '../viewmodels/satellite_monitoring_viewmodel.dart';
import '../widgets/pest_risk_card.dart';

class SatelliteMonitoringScreen extends StatefulWidget {
  final String? initialFieldId;
  const SatelliteMonitoringScreen({super.key, this.initialFieldId});

  @override
  State<SatelliteMonitoringScreen> createState() =>
      _SatelliteMonitoringScreenState();
}

class _SatelliteMonitoringScreenState
    extends State<SatelliteMonitoringScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  VoidCallback? _fieldListener;
  SatelliteMonitoringViewModel? _satelliteVM;
  PestForecastViewModel? _pestVM;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _satelliteVM = context.read<SatelliteMonitoringViewModel>();
      _pestVM = context.read<PestForecastViewModel>();
      _satelliteVM!.initData(initialFieldId: widget.initialFieldId);

      _fieldListener = () {
        if (!mounted) return;
        if (_satelliteVM!.selectedField != null && _pestVM != null) {
          _pestVM!.fetchPestRiskForecast(
            latitude: _satelliteVM!.selectedField!.center.latitude,
            longitude: _satelliteVM!.selectedField!.center.longitude,
          );
        }
      };
      _satelliteVM!.addListener(_fieldListener!);

      if (_satelliteVM!.selectedField != null) {
        _fieldListener!();
      }
    });
  }

  @override
  void dispose() {
    if (_fieldListener != null && _satelliteVM != null) {
      _satelliteVM!.removeListener(_fieldListener!);
    }
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SatelliteMonitoringViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Stack(
            children: [
              // 1. Full-screen Map
              _buildFullScreenMap(viewModel),

              // 2. Top Bar (Back + Title + Mode Toggle)
              _buildTopBar(viewModel),

              // 3. Field Selector Chips (Horizontal scroll)
              _buildFieldChips(viewModel),

              // 4. Floating Stats Card (Top Right)
              if (viewModel.selectedField != null)
                _buildFloatingStats(viewModel),

              // 5. Bottom Sheet (Draggable)
              _buildBottomSheet(viewModel),

              // 6. Zoom Controls
              _buildZoomControls(),
            ],
          ),
        );
      },
    );
  }

  // ============ FULL SCREEN MAP ============
  Widget _buildFullScreenMap(SatelliteMonitoringViewModel viewModel) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: viewModel.selectedField?.center ??
            const LatLng(10.033333, 105.783333),
        initialZoom: 15.5,
        minZoom: 3.0,
        maxZoom: 18.0,
        onTap: (_, __) {
          // Collapse sheet when tapping map
          _sheetController.animateTo(
            0.12,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _getMapTileUrl(viewModel),
          userAgentPackageName: 'com.agritech.app',
        ),
        // Farm polygons
        PolygonLayer(
          polygons: viewModel.fields.map((field) {
            final isSelected = viewModel.selectedField?.id == field.id;
            final Color overlayColor = viewModel.mapMode == 'NDVI'
                ? viewModel.getNDVIColor(field.ndviValue)
                : viewModel.getMoistureColor(field.soilMoisture);

            return Polygon(
              points: field.polygonPoints,
              color: overlayColor.withValues(alpha: isSelected ? 0.5 : 0.3),
              borderColor: isSelected ? Colors.white : overlayColor,
              borderStrokeWidth: isSelected ? 3 : 1.5,
            );
          }).toList(),
        ),
        // Farm markers
        MarkerLayer(
          markers: viewModel.fields.map((field) {
            final isSelected = viewModel.selectedField?.id == field.id;
            return Marker(
              point: field.center,
              width: isSelected ? 56 : 44,
              height: isSelected ? 56 : 44,
              child: GestureDetector(
                onTap: () {
                  viewModel.selectField(field);
                  _mapController.move(field.center, 16.0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: viewModel.mapMode == 'NDVI'
                        ? viewModel.getNDVIColor(field.ndviValue)
                        : viewModel.getMoistureColor(field.soilMoisture),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white70,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: isSelected ? 12 : 6,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: isSelected ? 28 : 22,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============ TOP BAR ============
  Widget _buildTopBar(SatelliteMonitoringViewModel viewModel) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back button
              _buildCircleButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    viewModel.selectedField?.name ?? 'Chọn vùng trồng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111813),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Mode Toggle
              _buildModeToggle(viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF111813), size: 22),
      ),
    );
  }

  Widget _buildModeToggle(SatelliteMonitoringViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(viewModel, 'NDVI', Icons.eco),
          _buildModeButton(viewModel, 'Soil Moisture', Icons.water_drop),
        ],
      ),
    );
  }

  Widget _buildModeButton(
      SatelliteMonitoringViewModel viewModel, String mode, IconData icon) {
    final isActive = viewModel.mapMode == mode;
    return GestureDetector(
      onTap: () => viewModel.setMapMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0BDA50) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  // ============ FIELD CHIPS ============
  Widget _buildFieldChips(SatelliteMonitoringViewModel viewModel) {
    if (viewModel.fields.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: viewModel.fields.length,
            itemBuilder: (context, index) {
              final field = viewModel.fields[index];
              final isSelected = viewModel.selectedField?.id == field.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    viewModel.selectField(field);
                    _mapController.move(field.center, 16.0);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0BDA50)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0BDA50)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF0BDA50).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.grass,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0BDA50),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          field.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF111813),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============ FLOATING STATS ============
  Widget _buildFloatingStats(SatelliteMonitoringViewModel viewModel) {
    final field = viewModel.selectedField!;
    final isNdviMode = viewModel.mapMode == 'NDVI';
    final value = isNdviMode ? field.ndviValue : field.soilMoisture;
    final color = isNdviMode
        ? viewModel.getNDVIColor(value)
        : viewModel.getMoistureColor(value);

    return Positioned(
      top: 160,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isNdviMode ? 'NDVI' : 'Độ ẩm',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isNdviMode
                      ? value.toStringAsFixed(2)
                      : '${value.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isNdviMode ? field.ndviStatus : field.soilMoistureStatus,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ZOOM CONTROLS ============
  Widget _buildZoomControls() {
    return Positioned(
      bottom: 140,
      right: 16,
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              ),
            ),
            Container(height: 1, width: 36, color: Colors.grey[200]),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ BOTTOM SHEET ============
  Widget _buildBottomSheet(SatelliteMonitoringViewModel viewModel) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.12, 0.45, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag Handle
              _buildDragHandle(),

              // Quick Stats Row
              _buildQuickStats(viewModel),

              // Divider
              Divider(color: Colors.grey[200], height: 1),

              // Detailed Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NDVI Chart
                    _buildNDVIChart(viewModel),
                    const SizedBox(height: 24),

                    // Pest Warnings
                    _buildPestWarnings(),
                    const SizedBox(height: 24),

                    // Field Details
                    _buildFieldDetails(viewModel),
                    const SizedBox(height: 24),

                    // Map Layer Selector
                    _buildMapLayerSelector(viewModel),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildQuickStats(SatelliteMonitoringViewModel viewModel) {
    if (viewModel.selectedField == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Chọn một vùng trồng để xem chi tiết',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final field = viewModel.selectedField!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.eco,
              label: 'NDVI',
              value: field.ndviValue.toStringAsFixed(2),
              color: viewModel.getNDVIColor(field.ndviValue),
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey[200]),
          Expanded(
            child: _buildStatItem(
              icon: Icons.water_drop,
              label: 'Độ ẩm',
              value: '${field.soilMoisture.toStringAsFixed(0)}%',
              color: viewModel.getMoistureColor(field.soilMoisture),
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey[200]),
          Expanded(
            child: _buildStatItem(
              icon: Icons.square_foot,
              label: 'Diện tích',
              value: '${field.area.toStringAsFixed(1)} ha',
              color: const Color(0xFF0BDA50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNDVIChart(SatelliteMonitoringViewModel viewModel) {
    if (viewModel.selectedField == null) return const SizedBox.shrink();

    final history = viewModel.selectedField!.ndviHistory;
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Chưa có dữ liệu lịch sử NDVI',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Biểu đồ NDVI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111813),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0BDA50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${history.length} điểm dữ liệu',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0BDA50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.2,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.2,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < history.length) {
                        final date = history[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 1,
              lineBarsData: [
                LineChartBarData(
                  spots: history.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.value);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFF0BDA50),
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF0BDA50),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF0BDA50).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPestWarnings() {
    return Consumer<PestForecastViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final forecast = viewModel.forecast;
        if (forecast == null || forecast.warnings.isEmpty) {
          return const SizedBox.shrink();
        }

        final warnings = forecast.warnings
            .where((w) => w.riskLevel == 'high' || w.riskLevel == 'medium')
            .toList();

        if (warnings.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Cảnh báo sâu bệnh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111813),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${warnings.length} cảnh báo',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map((w) => PestRiskCard(warning: w)),
          ],
        );
      },
    );
  }

  Widget _buildFieldDetails(SatelliteMonitoringViewModel viewModel) {
    if (viewModel.selectedField == null) return const SizedBox.shrink();

    final field = viewModel.selectedField!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin vùng trồng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111813),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildDetailRow('Tên', field.name),
              _buildDetailRow('Loại cây trồng', field.cropType),
              _buildDetailRow(
                  'Diện tích', '${field.area.toStringAsFixed(2)} ha'),
              _buildDetailRow('Trạng thái NDVI', field.ndviStatus),
              _buildDetailRow('Trạng thái độ ẩm', field.soilMoistureStatus),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111813),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayerSelector(SatelliteMonitoringViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lớp bản đồ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111813),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLayerOption(
                viewModel, 'Satellite', 'Vệ tinh', Icons.satellite_alt),
            const SizedBox(width: 12),
            _buildLayerOption(viewModel, 'Street', 'Đường phố', Icons.map),
            const SizedBox(width: 12),
            _buildLayerOption(viewModel, 'Terrain', 'Địa hình', Icons.terrain),
          ],
        ),
      ],
    );
  }

  Widget _buildLayerOption(
    SatelliteMonitoringViewModel viewModel,
    String type,
    String label,
    IconData icon,
  ) {
    final isSelected = viewModel.mapLayerType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.setMapLayerType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0BDA50) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0BDA50) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMapTileUrl(SatelliteMonitoringViewModel viewModel) {
    switch (viewModel.mapLayerType) {
      case 'Street':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'Terrain':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
      case 'Satellite':
      default:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }
}
