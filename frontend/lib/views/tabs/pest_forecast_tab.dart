import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/api_models.dart';
import '../../models/crop_field.dart';
import '../../viewmodels/farm_map_viewmodel.dart';
import '../../viewmodels/pest_forecast_viewmodel.dart';
import '../../widgets/pest_risk_card.dart';

class PestForecastTab extends StatefulWidget {
  const PestForecastTab({super.key});

  @override
  State<PestForecastTab> createState() => _PestForecastTabState();
}

class _PestForecastTabState extends State<PestForecastTab> {
  final MapController _mapController = MapController();
  CropField? _selectedField;
  bool _isLoadingForecast = false;
  PestRiskForecastResponseDTO? _currentForecast;
  String? _errorMessage;
  int _selectedYearsBack = 5; // Default: 5 years

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farmViewModel = context.read<FarmMapViewModel>();
      farmViewModel.initData();
    });
  }

  Future<void> _onFieldTapped(CropField field) async {
    setState(() {
      _selectedField = field;
      _isLoadingForecast = true;
      _errorMessage = null;
    });

    // Animate map to the selected field
    _mapController.move(field.center, 16.0);

    try {
      final pestViewModel = context.read<PestForecastViewModel>();
      await pestViewModel.fetchPestRiskForecast(
        latitude: field.center.latitude,
        longitude: field.center.longitude,
        yearsBack: _selectedYearsBack,
      );

      setState(() {
        _currentForecast = pestViewModel.forecast;
        _isLoadingForecast = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingForecast = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmMapViewModel>(
      builder: (context, farmViewModel, child) {
        if (farmViewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0BDA50)),
          );
        }

        if (farmViewModel.fields.isEmpty) {
          return _buildEmptyState();
        }

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMap(farmViewModel),
                ),
                Expanded(
                  flex: 2,
                  child: _buildFieldsList(farmViewModel),
                ),
              ],
            ),
            if (_selectedField != null) _buildBottomSheet(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có vùng trồng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy tạo vùng trồng trong tab "Bản đồ" để xem dự báo rủi ro sâu bệnh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(FarmMapViewModel farmViewModel) {
    // Calculate bounds to fit all fields
    final allPoints =
        farmViewModel.fields.expand((field) => field.polygonPoints).toList();

    final center = allPoints.isNotEmpty
        ? LatLng(
            allPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
                allPoints.length,
            allPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
                allPoints.length,
          )
        : const LatLng(10.033333, 105.783333);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.agritech.app',
        ),
        PolygonLayer(
          polygons: farmViewModel.fields.map((field) {
            final isSelected = _selectedField?.id == field.id;
            return Polygon(
              points: field.polygonPoints,
              color: isSelected
                  ? const Color(0xFF0BDA50).withValues(alpha: 0.4)
                  : _getFieldColor(field.cropType).withValues(alpha: 0.3),
              borderColor: isSelected
                  ? const Color(0xFF0BDA50)
                  : _getFieldColor(field.cropType),
              borderStrokeWidth: isSelected ? 3 : 2,
            );
          }).toList(),
        ),
        MarkerLayer(
          markers: farmViewModel.fields.map((field) {
            return Marker(
              point: field.center,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _onFieldTapped(field),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCropIcon(field.cropType),
                    color: _getFieldColor(field.cropType),
                    size: 24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSheetHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildFieldHeader(),
                    const SizedBox(height: 20),
                    if (_isLoadingForecast)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                              color: Color(0xFF0BDA50)),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildErrorCard()
                    else if (_currentForecast != null)
                      _buildForecastContent(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildFieldHeader() {
    if (_selectedField == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getFieldColor(_selectedField!.cropType)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCropIcon(_selectedField!.cropType),
                color: _getFieldColor(_selectedField!.cropType),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedField!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedField!.cropType} • ${_selectedField!.area.toStringAsFixed(2)} ha',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedField = null;
                  _currentForecast = null;
                });
              },
              icon: const Icon(Icons.close),
              color: Colors.grey.shade600,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Xem lịch sử:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [5, 10, 15, 20].map((years) {
                    final isSelected = _selectedYearsBack == years;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('$years năm'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected && _selectedYearsBack != years) {
                            setState(() {
                              _selectedYearsBack = years;
                            });
                            _onFieldTapped(_selectedField!);
                          }
                        },
                        selectedColor:
                            const Color(0xFF0BDA50).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF0BDA50),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0BDA50)
                              : Colors.grey.shade700,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF0BDA50)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(
            'Không thể tải dữ liệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi không xác định',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _onFieldTapped(_selectedField!),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0BDA50),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastContent() {
    if (_currentForecast == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRiskSummaryCard(_currentForecast!),
        const SizedBox(height: 24),
        _buildSectionTitle('Cảnh báo hoạt động'),
        const SizedBox(height: 12),
        _buildWarningsList(_currentForecast!.warnings),
        const SizedBox(height: 24),
        _buildSectionTitle('Lịch sử xuất hiện ($_selectedYearsBack năm)'),
        const SizedBox(height: 16),
        _buildHistoricalChartCard(_currentForecast!.pestSummary),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildRiskSummaryCard(PestRiskForecastResponseDTO forecast) {
    final bool highRisk = forecast.warnings.any((w) => w.riskLevel == 'high');
    final bool mediumRisk =
        forecast.warnings.any((w) => w.riskLevel == 'medium');

    Color color;
    Color bgColor;
    String title;
    String message;
    IconData icon;

    if (highRisk) {
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      title = 'Cảnh báo Rủi ro Cao';
      message =
          'Dữ liệu lịch sử cho thấy nguy cơ bùng phát dịch bệnh cao tại vùng này.';
      icon = Icons.warning_rounded;
    } else if (mediumRisk) {
      color = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      title = 'Rủi ro Trung bình';
      message = 'Một số loài sâu bệnh đã xuất hiện trong những năm gần đây.';
      icon = Icons.info_rounded;
    } else {
      color = const Color(0xFF059669);
      bgColor = const Color(0xFFECFDF5);
      title = 'Rủi ro Thấp';
      message =
          'Không phát hiện lịch sử dịch bệnh đáng kể trong $_selectedYearsBack năm qua.';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsList(List<PestWarningDTO> warnings) {
    if (warnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Không có cảnh báo nào',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: warnings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => PestRiskCard(warning: warnings[index]),
    );
  }

  Widget _buildHistoricalChartCard(Map<String, PestSummaryDTO> pestSummary) {
    if (pestSummary.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu lịch sử',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final Map<int, int> yearlyTotals = {};
    for (var pest in pestSummary.values) {
      pest.yearlyOccurrences.forEach((yearStr, count) {
        final year = int.tryParse(yearStr) ?? 0;
        if (year > 0) {
          yearlyTotals[year] = (yearlyTotals[year] ?? 0) + count;
        }
      });
    }

    if (yearlyTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu lịch sử',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final sortedYears = yearlyTotals.keys.toList()..sort();
    final double maxY =
        yearlyTotals.values.reduce((a, b) => a > b ? a : b).toDouble();
    final int totalOccurrences = yearlyTotals.values.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pest List Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Loại sâu bệnh phát hiện',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...pestSummary.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0BDA50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.vietnameseName ?? entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value.totalOccurrences} lần',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0BDA50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng số lần phát hiện:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '$totalOccurrences lần',
                      style: const TextStyle(
                        fontSize: 16,
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
        const SizedBox(height: 16),
        // Chart
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biểu đồ theo năm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY * 1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sortedYears.length) {
                              return Text(
                                sortedYears[index].toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 10 ? 5 : 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: sortedYears.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: yearlyTotals[entry.value]!.toDouble(),
                            color: const Color(0xFF0BDA50),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getFieldColor(String cropType) {
    switch (cropType) {
      case 'Lúa':
        return const Color(0xFF34D399);
      case 'Cây ăn trái':
        return const Color(0xFFFBBF24);
      case 'Cây công nghiệp':
        return const Color(0xFFA78BFA);
      default:
        return const Color(0xFF0BDA50);
    }
  }

  IconData _getCropIcon(String cropType) {
    switch (cropType) {
      case 'Lúa':
        return Icons.grass;
      case 'Cây ăn trái':
        return Icons.park;
      case 'Cây công nghiệp':
        return Icons.factory;
      default:
        return Icons.agriculture;
    }
  }

  Widget _buildFieldsList(FarmMapViewModel farmViewModel) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vùng trồng của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${farmViewModel.fields.length} vùng đang quản lý',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: farmViewModel.fields.length,
              itemBuilder: (context, index) {
                final field = farmViewModel.fields[index];
                final isSelected = _selectedField?.id == field.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0BDA50).withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0BDA50)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onFieldTapped(field),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getFieldColor(field.cropType)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getCropIcon(field.cropType),
                                color: _getFieldColor(field.cropType),
                                size: 24,
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${field.area.toStringAsFixed(2)} ha • ${field.cropType}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF0BDA50),
                                size: 24,
                              )
                            else
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
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
}
