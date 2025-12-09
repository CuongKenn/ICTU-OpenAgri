// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/api_models.dart';
import '../viewmodels/commodity_price_viewmodel.dart';
import 'commodity_price_detail_view.dart';

class CommodityPricesListView extends StatefulWidget {
  const CommodityPricesListView({super.key});

  @override
  State<CommodityPricesListView> createState() =>
      _CommodityPricesListViewState();
}

class _CommodityPricesListViewState extends State<CommodityPricesListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel =
          Provider.of<CommodityPriceViewModel>(context, listen: false);
      viewModel.loadCommodities();
      viewModel.loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thị Trường Nông Sản',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CommodityPriceViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.commodities.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C853)));
          }

          if (viewModel.error != null && viewModel.commodities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${viewModel.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadCommodities(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Category Filter Tabs
              if (viewModel.categories.isNotEmpty)
                Container(
                  color: Colors.grey[50],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryTab(
                          'Tất cả',
                          viewModel.selectedCategory == null,
                          () {
                            viewModel.setSelectedCategory(null);
                            viewModel.loadCommodities();
                          },
                        ),
                        const SizedBox(width: 8),
                        ...viewModel.categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryTab(
                              _formatCategory(category),
                              viewModel.selectedCategory == category,
                              () {
                                viewModel.setSelectedCategory(category);
                                viewModel.loadCommodities(category: category);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Table Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Tên',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Giá gần nhất',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Thay đổi 24h',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Commodity List
              Expanded(
                child: ListView.separated(
                  itemCount: viewModel.commodities.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final commodity = viewModel.commodities[index];
                    return _CommodityRow(commodity: commodity);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C853) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C853) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    const categoryLabels = {
      'fruits': 'Trái cây',
      'nuts': 'Các loại hạt',
      'rubber': 'Cao su',
      'spices': 'Gia vị',
      'grains': 'Ngũ cốc',
      'coffee': 'Cà phê',
    };
    final key = category.toLowerCase();
    final translated = categoryLabels[key];
    if (translated != null) {
      return translated;
    }
    return category.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class _CommodityRow extends StatelessWidget {
  final CommodityPriceDTO commodity;

  const _CommodityRow({required this.commodity});

  @override
  Widget build(BuildContext context) {
    final priceFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final isPositive = (commodity.priceChangePercent24h ?? 0) >= 0;
    final changeColor =
        isPositive ? const Color(0xFF00C853) : const Color(0xFFE53935);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) =>
                  CommodityPriceViewModel()..loadCommodityDetail(commodity.id),
              child: const CommodityPriceDetailView(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Name and Market
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commodity.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    commodity.unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Current Price
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceFormat.format(commodity.currentPrice ?? 0),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${priceFormat.format(commodity.minPrice ?? 0)} - ${priceFormat.format(commodity.maxPrice ?? 0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Price Change
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${(commodity.priceChangePercent24h ?? 0).toStringAsFixed(2)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: changeColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
