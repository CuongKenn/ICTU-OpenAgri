import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/commodity_price.dart';
import '../viewmodels/commodity_price_viewmodel.dart';

class CommodityPriceDetailView extends StatelessWidget {
  const CommodityPriceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chi Tiết Giá',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CommodityPriceViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.selectedCommodity == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            );
          }

          if (viewModel.error != null || viewModel.selectedCommodity == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${viewModel.error ?? "Không tìm thấy dữ liệu"}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          final detail = viewModel.selectedCommodity!;
          final commodity = detail.commodity;
          final priceFormat = NumberFormat.currency(
              locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
          final isPositive = (commodity.priceChangePercent24h ?? 0) >= 0;
          final changeColor =
              isPositive ? const Color(0xFF00C853) : const Color(0xFFE53935);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với giá hiện tại - Cleaner design
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            commodity.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              commodity.unit,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            priceFormat.format(commodity.currentPrice ?? 0),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: changeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: changeColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isPositive ? '+' : ''}${(commodity.priceChangePercent24h ?? 0).toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: changeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '24h',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Cards - Binance style
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatsCard(
                          title: 'Giá cao nhất',
                          value: priceFormat.format(commodity.maxPrice ?? 0),
                          color: const Color(0xFF00C853),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatsCard(
                          title: 'Giá thấp nhất',
                          value: priceFormat.format(commodity.minPrice ?? 0),
                          color: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),

                // Biểu đồ giá - Improved
                Container(
                  height: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: _buildPriceChart(detail.chartData, isPositive),
                ),

                const SizedBox(height: 24),

                // Lịch sử giá - Table style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch sử giá gần đây',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ngày',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Giá',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Table Rows
                            ...detail.priceHistory.reversed
                                .take(10)
                                .map((price) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.grey[200]!, width: 1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(
                                        DateFormat('yyyy-MM-dd')
                                            .parse(price.date),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      priceFormat.format(price.price),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceChart(List<ChartDataPoint> chartData, bool isPositive) {
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu biểu đồ',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = chartData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final data = entry.value;
      return FlSpot(index, data.price);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.02;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[100]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55, // Tăng khoảng cách để số không bị cắt
              interval: (maxY - minY) / 5,
              getTitlesWidget: (value, meta) {
                if (value == minY || value == maxY) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    NumberFormat.compactCurrency(
                      locale: 'vi_VN',
                      symbol: '',
                      decimalDigits: 1,
                    ).format(value),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              // Tính toán interval để hiển thị tối đa 5 mốc thời gian, tránh lặp
              interval: chartData.length > 5 ? chartData.length / 4 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  final dateStr = chartData[index].date;
                  final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color:
                isPositive ? const Color(0xFF00C853) : const Color(0xFFE53935),
            barWidth: 2,
            isStrokeCapRound: true,
            // Hiển thị chấm tròn ở điểm cuối cùng
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                return spot.x == chartData.length - 1;
              },
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: barData.color ?? Colors.green,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isPositive
                          ? const Color(0xFF00C853)
                          : const Color(0xFFE53935))
                      .withValues(alpha: 0.25),
                  (isPositive
                          ? const Color(0xFF00C853)
                          : const Color(0xFFE53935))
                      .withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index >= 0 && index < chartData.length) {
                  final data = chartData[index];
                  final dateStr = data.date;
                  final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                  return LineTooltipItem(
                    '${DateFormat('dd/MM/yyyy').format(date)}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: NumberFormat.currency(
                                locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
                            .format(touchedSpot.y),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }
                return null;
              }).toList();
            },
          ),
          // Thêm đường gióng (crosshair) khi chạm vào
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: Colors.grey.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5], // Đường nét đứt
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: barData.color ?? Colors.green,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
