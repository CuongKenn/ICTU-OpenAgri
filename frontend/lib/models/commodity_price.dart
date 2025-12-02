// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

class PricePoint {
  final String date;
  final double price;

  PricePoint({
    required this.date,
    required this.price,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: json['date'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class CommodityPrice {
  final String id;
  final String name;
  final String nameEn;
  final String unit;
  final String category;
  final List<PricePoint> prices;
  final double? currentPrice;
  final double? priceChange24h;
  final double? priceChangePercent24h;
  final double? minPrice;
  final double? maxPrice;

  CommodityPrice({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.unit,
    required this.category,
    required this.prices,
    this.currentPrice,
    this.priceChange24h,
    this.priceChangePercent24h,
    this.minPrice,
    this.maxPrice,
  });

  factory CommodityPrice.fromJson(Map<String, dynamic> json) {
    return CommodityPrice(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      unit: json['unit'] as String,
      category: json['category'] as String,
      prices: (json['prices'] as List)
          .map((p) => PricePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      currentPrice: json['current_price'] != null
          ? (json['current_price'] as num).toDouble()
          : null,
      priceChange24h: json['price_change_24h'] != null
          ? (json['price_change_24h'] as num).toDouble()
          : null,
      priceChangePercent24h: json['price_change_percent_24h'] != null
          ? (json['price_change_percent_24h'] as num).toDouble()
          : null,
      minPrice: json['min_price'] != null
          ? (json['min_price'] as num).toDouble()
          : null,
      maxPrice: json['max_price'] != null
          ? (json['max_price'] as num).toDouble()
          : null,
    );
  }
}

class ChartDataPoint {
  final String date;
  final double price;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? volume;

  ChartDataPoint({
    required this.date,
    required this.price,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: json['date'] as String,
      price: (json['price'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume:
          json['volume'] != null ? (json['volume'] as num).toDouble() : null,
    );
  }
}

class CommodityPriceDetail {
  final CommodityPrice commodity;
  final List<ChartDataPoint> chartData;
  final List<PricePoint> priceHistory;

  CommodityPriceDetail({
    required this.commodity,
    required this.chartData,
    required this.priceHistory,
  });

  factory CommodityPriceDetail.fromJson(Map<String, dynamic> json) {
    return CommodityPriceDetail(
      commodity:
          CommodityPrice.fromJson(json['commodity'] as Map<String, dynamic>),
      chartData: (json['chart_data'] as List)
          .map((c) => ChartDataPoint.fromJson(c as Map<String, dynamic>))
          .toList(),
      priceHistory: (json['price_history'] as List)
          .map((p) => PricePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CommodityPriceListResponse {
  final List<CommodityPrice> commodities;
  final int total;
  final String lastUpdated;

  CommodityPriceListResponse({
    required this.commodities,
    required this.total,
    required this.lastUpdated,
  });

  factory CommodityPriceListResponse.fromJson(Map<String, dynamic> json) {
    return CommodityPriceListResponse(
      commodities: (json['commodities'] as List)
          .map((c) => CommodityPrice.fromJson(c as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      lastUpdated: json['last_updated'] as String,
    );
  }
}
