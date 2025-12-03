// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/crop_field.dart';
import '../viewmodels/satellite_monitoring_viewmodel.dart';
import '../viewmodels/pest_forecast_viewmodel.dart';
import '../widgets/pest_risk_card.dart';

class SatelliteMonitoringScreen extends StatefulWidget {
  final String? initialFieldId;
  const SatelliteMonitoringScreen({super.key, this.initialFieldId});

  @override
  State<SatelliteMonitoringScreen> createState() =>
      _SatelliteMonitoringScreenState();
}

class _SatelliteMonitoringScreenState extends State<SatelliteMonitoringScreen> {
  final MapController _mapController = MapController();

  VoidCallback? _fieldListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final satelliteVM = context.read<SatelliteMonitoringViewModel>();
      satelliteVM.initData(initialFieldId: widget.initialFieldId);

      _fieldListener = () {
        if (satelliteVM.selectedField != null) {
          context.read<PestForecastViewModel>().fetchPestRiskForecast(
                latitude: satelliteVM.selectedField!.center.latitude,
                longitude: satelliteVM.selectedField!.center.longitude,
              );
        }
      };
      satelliteVM.addListener(_fieldListener!);
      
      // Trigger initial fetch if field is already selected
      if (satelliteVM.selectedField != null) {
        _fieldListener!();
      }
    });
  }

  @override
  void dispose() {
    if (_fieldListener != null) {
      context.read<SatelliteMonitoringViewModel>().removeListener(_fieldListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Consumer<SatelliteMonitoringViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F8F6),
          body: SafeArea(
            child: isDesktop
                ? _buildDesktopLayout(viewModel)
                : _buildMobileLayout(viewModel),
          ),
        );
      },
    );
  }

  // ============ DESKTOP LAYOUT ============
  Widget _buildDesktopLayout(SatelliteMonitoringViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF111813)),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Giám sát Vệ tinh Vùng trồng',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111813),
                ),
              ),
            ],
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
                _buildSidebar(viewModel, isMobile: false),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildMapSection(viewModel)),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 4,
                              child: _buildSatelliteDataCard(viewModel)),
                          const SizedBox(width: 32),
                          Expanded(flex: 6, child: _buildChartCard(viewModel)),
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
  Widget _buildMobileLayout(SatelliteMonitoringViewModel viewModel) {
    return Column(
      children: [
        // 1. MAP SECTION (Top) - Chiếm 55% màn hình
        Expanded(
          flex: 55,
          child: Stack(
            children: [
              _buildMapSection(viewModel, isMobile: true),
              // Back button overlay
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
              // Mode selector overlay (centered)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeChip(viewModel, 'NDVI', 'NDVI', Icons.eco),
                        const SizedBox(width: 4),
                        _buildModeChip(viewModel, 'Độ ẩm', 'Soil Moisture',
                            Icons.water_drop),
                      ],
                    ),
                  ),
                ),
              ),
              // Nút mở bảng điều khiển đè lên map (góc dưới trái)
              Positioned(
                bottom: 20,
                left: 16,
                child: FloatingActionButton(
                  onPressed: () => _showControlPanelBottomSheet(viewModel),
                  backgroundColor: const Color(0xFF0BDA50),
                  elevation: 4,
                  child: const Icon(Icons.tune, color: Colors.white, size: 24),
                ),
              ),
              // Zoom controls (góc dưới phải)
              Positioned(
                bottom: 20,
                right: 16,
                child: Container(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, size: 28),
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                        color: Colors.black,
                      ),
                      Container(
                          height: 1, width: 40, color: Colors.grey.shade300),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 28),
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. INFO SECTION - Chiếm 45% màn hình
        Expanded(
          flex: 45,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F6),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Thông số Vệ tinh',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111813),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSatelliteDataCard(viewModel),
                  const SizedBox(height: 16),
                  _buildPestRiskSection(),
                  const SizedBox(height: 16),
                  _buildChartCard(viewModel),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showControlPanelBottomSheet(SatelliteMonitoringViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: _buildSidebar(viewModel, isMobile: true),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDatePicker(SatelliteMonitoringViewModel viewModel,
      StateSetter? setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Chọn tháng/năm',
    );

    if (picked != null && picked != viewModel.selectedDate) {
      if (setModalState != null) {
        setModalState(() {
          viewModel.setSelectedDate(picked);
        });
      } else {
        viewModel.setSelectedDate(picked);
      }
    }
  }

  void _showDataLayerPicker(
      SatelliteMonitoringViewModel viewModel, StateSetter? setModalState) {
    final layers = ['Tất cả', 'NDVI', 'Độ ẩm đất', 'Nhiệt độ bề mặt', 'EVI'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn lớp dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111813),
              ),
            ),
            const SizedBox(height: 16),
            ...layers.map((layer) => ListTile(
                  leading: Icon(
                    viewModel.selectedDataLayer == layer
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: viewModel.selectedDataLayer == layer
                        ? const Color(0xFF0BDA50)
                        : Colors.grey,
                  ),
                  title: Text(
                    layer,
                    style: TextStyle(
                      fontWeight: viewModel.selectedDataLayer == layer
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: viewModel.selectedDataLayer == layer
                          ? const Color(0xFF0BDA50)
                          : const Color(0xFF111813),
                    ),
                  ),
                  onTap: () {
                    if (setModalState != null) {
                      setModalState(() {
                        viewModel.setSelectedDataLayer(layer);
                      });
                    } else {
                      viewModel.setSelectedDataLayer(layer);
                    }
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============ MAP SECTION ============
  Widget _buildMapSection(SatelliteMonitoringViewModel viewModel,
      {bool isMobile = false}) {
    return ClipRRect(
      borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: viewModel.selectedField?.center ??
                  const LatLng(10.033333, 105.783333),
              initialZoom: 15.5,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapTileUrl(viewModel),
                userAgentPackageName: 'com.agritech.app',
              ),
              PolygonLayer(
                polygons: viewModel.fields.map((field) {
                  final isSelected = viewModel.selectedField?.id == field.id;
                  final Color overlayColor = viewModel.mapMode == 'NDVI'
                      ? viewModel.getNDVIColor(field.ndviValue)
                      : viewModel.getMoistureColor(field.ndviValue * 100);

                  return Polygon(
                    points: field.polygonPoints,
                    color: overlayColor.withValues(alpha: 0.6),
                    borderColor: isSelected ? Colors.white : overlayColor,
                    borderStrokeWidth: isSelected ? 3 : 2,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: viewModel.fields.map((field) {
                  return Marker(
                    point: field.center,
                    width: 50,
                    height: 50,
                    child: InkWell(
                      onTap: () {
                        viewModel.selectField(field);
                        _mapController.move(field.center, 16.0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: viewModel.mapMode == 'NDVI'
                              ? viewModel.getNDVIColor(field.ndviValue)
                              : viewModel
                                  .getMoistureColor(field.ndviValue * 100),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: viewModel.selectedField?.id == field.id
                                ? Colors.yellow
                                : Colors.white,
                            width:
                                viewModel.selectedField?.id == field.id ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // No old controls here anymore - using new overlay system
        ],
      ),
    );
  }

  // ============ SIDEBAR (DESKTOP & MOBILE CONTENT) ============
  Widget _buildSidebar(SatelliteMonitoringViewModel viewModel,
      {bool isMobile = false, StateSetter? setModalState}) {
    // Mobile Layout (Tabbed Interface)
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildControlTabs(viewModel, setModalState: setModalState),
          const SizedBox(height: 20),
          if (viewModel.activeControlTab == 'filter')
            _buildFilterContent(viewModel, setModalState: setModalState),
          if (viewModel.activeControlTab == 'layers')
            _buildLayersContent(viewModel, setModalState: setModalState),
          if (viewModel.activeControlTab == 'legend') _buildLegendContent(),
          const SizedBox(height: 24),
          const Text(
            'Chọn vùng trồng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111813),
            ),
          ),
          const SizedBox(height: 12),
          ...viewModel.fields
              .map((field) => _buildFieldSelectorItem(viewModel, field)),
        ],
      );
    }

    // Desktop Layout (Full Sidebar)
    return Container(
      width: 380,
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giám sát Vệ tinh',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111813),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Theo dõi sức khỏe cây trồng và độ ẩm đất theo thời gian thực',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 0. Pest Risk Forecast (New)
                _buildPestRiskSection(),
                const SizedBox(height: 24),

                // 1. Field Selection
                const Text(
                  'Khu vực giám sát',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5C52),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: viewModel.fields.map((field) {
                      final isSelected = viewModel.selectedField == field;
                      return InkWell(
                        onTap: () => viewModel.selectField(field),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0BDA50)
                                    .withValues(alpha: 0.05)
                                : Colors.transparent,
                            border: field != viewModel.fields.last
                                ? Border(
                                    bottom:
                                        BorderSide(color: Colors.grey.shade100))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0BDA50)
                                          .withValues(alpha: 0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.grass,
                                  color: isSelected
                                      ? const Color(0xFF0BDA50)
                                      : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      field.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF0BDA50)
                                            : const Color(0xFF111813),
                                      ),
                                    ),
                                    Text(
                                      '${field.area} ha • ${field.cropType}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF0BDA50), size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),

                // 2. Date Selection
                const Text(
                  'Thời gian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5C52),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: viewModel.selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF0BDA50),
                              onPrimary: Colors.white,
                              onSurface: Color(0xFF111813),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      viewModel.setSelectedDate(picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 20, color: Color(0xFF4A5C52)),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd/MM/yyyy')
                              .format(viewModel.selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111813),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 3. Satellite Data
                const Text(
                  'Dữ liệu phân tích',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5C52),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSatelliteDataCard(viewModel),

                const SizedBox(height: 24),
                _buildChartCard(viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ CARDS & COMPONENTS ============

  Widget _buildSatelliteDataCard(SatelliteMonitoringViewModel viewModel) {
    if (viewModel.selectedField == null) return const SizedBox();

    final soilMoisture = viewModel.selectedField!.soilMoisture;
    final ndvi = viewModel.selectedField!.ndviValue;
    final soilMoistureStatus = viewModel.selectedField!.soilMoistureStatus;
    final ndviStatus = viewModel.selectedField!.ndviStatus;

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
                      viewModel.selectedField!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${viewModel.selectedField!.area} ha • ${viewModel.selectedField!.cropType}',
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
            status: ndviStatus,
            statusColor: viewModel.getNDVIColor(ndvi),
          ),
          const SizedBox(height: 20),
          // Sentinel-1
          _buildDataRow(
            icon: Icons.radar_outlined,
            title: 'Sentinel-1 (Radar)',
            value: soilMoisture.toStringAsFixed(0),
            unit: '%',
            status: soilMoistureStatus,
            statusColor: viewModel.getMoistureColor(soilMoisture),
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

  Widget _buildChartCard(SatelliteMonitoringViewModel viewModel) {
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
                viewModel.mapMode == 'NDVI' ? 'Biểu đồ NDVI' : 'Biểu đồ Độ ẩm',
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
                viewModel.mapMode == 'NDVI'
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

  Widget _buildControlTabs(SatelliteMonitoringViewModel viewModel,
      {StateSetter? setModalState}) {
    return Row(
      children: [
        _buildTab(viewModel, 'Bộ lọc', 'filter', Icons.filter_alt,
            setModalState: setModalState),
        _buildTab(viewModel, 'Lớp bản đồ', 'layers', Icons.layers,
            setModalState: setModalState),
        _buildTab(viewModel, 'Chú giải', 'legend', Icons.info_outline,
            setModalState: setModalState),
      ],
    );
  }

  Widget _buildTab(SatelliteMonitoringViewModel viewModel, String label,
      String value, IconData icon,
      {StateSetter? setModalState}) {
    final isActive = viewModel.activeControlTab == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (setModalState != null) {
              setModalState(() {
                viewModel.setActiveControlTab(value);
              });
            } else {
              viewModel.setActiveControlTab(value);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
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
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
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
      ),
    );
  }

  Widget _buildModeChip(SatelliteMonitoringViewModel viewModel, String label,
      String value, IconData icon) {
    final isActive = viewModel.mapMode == value;
    return GestureDetector(
      onTap: () => viewModel.setMapMode(value),
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

  String _getMapTileUrl(SatelliteMonitoringViewModel viewModel) {
    switch (viewModel.mapLayerType) {
      case 'Street':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'Terrain':
        // Using ESRI World Topo Map - reliable and free
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
      case 'Satellite':
      default:
        // Using ESRI World Imagery
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  // ... [Control Panel Helpers] ...
  Widget _buildFilterContent(SatelliteMonitoringViewModel viewModel,
      {StateSetter? setModalState}) {
    final dateText =
        'Tháng ${viewModel.selectedDate.month}/${viewModel.selectedDate.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterItem('Thời gian', dateText, Icons.calendar_today,
            onTap: () => _showDatePicker(viewModel, setModalState)),
        const SizedBox(height: 16),
        _buildFilterItem(
            'Lớp dữ liệu', viewModel.selectedDataLayer, Icons.layers,
            onTap: () => _showDataLayerPicker(viewModel, setModalState)),
      ],
    );
  }

  Widget _buildFilterItem(String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
      ),
    );
  }

  Widget _buildLayersContent(SatelliteMonitoringViewModel viewModel,
      {StateSetter? setModalState}) {
    return Column(
      children: [
        _buildMapLayerOption(
            viewModel, 'Satellite', 'Vệ tinh', Icons.satellite_alt,
            setModalState: setModalState),
        _buildMapLayerOption(viewModel, 'Street', 'Đường phố', Icons.map,
            setModalState: setModalState),
        _buildMapLayerOption(viewModel, 'Terrain', 'Địa hình', Icons.terrain,
            setModalState: setModalState),
      ],
    );
  }

  Widget _buildMapLayerOption(SatelliteMonitoringViewModel viewModel,
      String type, String label, IconData icon,
      {StateSetter? setModalState}) {
    final isSelected = viewModel.mapLayerType == type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (setModalState != null) {
          setModalState(() {
            viewModel.setMapLayerType(type);
          });
        } else {
          viewModel.setMapLayerType(type);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0BDA50) : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0BDA50) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF0BDA50) : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF0BDA50), size: 24),
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

  // Field selector item for control panel
  Widget _buildFieldSelectorItem(
      SatelliteMonitoringViewModel viewModel, CropField field) {
    final isSelected = viewModel.selectedField?.id == field.id;
    return GestureDetector(
      onTap: () {
        viewModel.selectField(field);
        _mapController.move(field.center, 16.0);
        if (MediaQuery.of(context).size.width <= 1024) {
          Navigator.pop(context); // Close bottom sheet
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0BDA50) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCropColor(field.cropType).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCropIcon(field.cropType),
                color: _getCropColor(field.cropType),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF0BDA50)
                          : const Color(0xFF111813),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.terrain, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${field.area.toStringAsFixed(1)} ha',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: viewModel
                              .getNDVIColor(field.ndviValue)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'NDVI: ${field.ndviValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: viewModel.getNDVIColor(field.ndviValue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF0BDA50), size: 24),
          ],
        ),
      ),
    );
  }

  // Helper methods for crop icons and colors
  IconData _getCropIcon(String cropType) {
    switch (cropType) {
      case 'Lúa':
        return Icons.grass;
      case 'Cây ăn trái':
        return Icons.park;
      case 'Rau màu':
        return Icons.eco;
      default:
        return Icons.agriculture;
    }
  }

  Color _getCropColor(String cropType) {
    switch (cropType) {
      case 'Lúa':
        return const Color(0xFFFBBF24);
      case 'Cây ăn trái':
        return const Color(0xFF10B981);
      case 'Rau màu':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF0BDA50);
    }
  }

  Widget _buildPestRiskSection() {
    return Consumer<PestForecastViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: LinearProgressIndicator());
        }
        
        final forecast = viewModel.forecast;
        if (forecast == null || forecast.warnings.isEmpty) {
          return const SizedBox.shrink();
        }

        // Only show the highest risk warning or a summary
        final highRisks = forecast.warnings.where((w) => w.riskLevel == 'high').toList();
        final mediumRisks = forecast.warnings.where((w) => w.riskLevel == 'medium').toList();
        
        if (highRisks.isEmpty && mediumRisks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cảnh báo Sâu bệnh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...highRisks.map((w) => PestRiskCard(warning: w)),
            ...mediumRisks.map((w) => PestRiskCard(warning: w)),
          ],
        );
      },
    );
  }
}


