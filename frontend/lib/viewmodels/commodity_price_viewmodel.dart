import 'package:flutter/foundation.dart';
import '../models/commodity_price.dart';
import '../services/commodity_price_service.dart';

class CommodityPriceViewModel extends ChangeNotifier {
  final CommodityPriceService _service = CommodityPriceService();

  List<CommodityPrice> _commodities = [];
  CommodityPriceDetail? _selectedCommodity;
  bool _isLoading = false;
  String? _error;
  List<String> _categories = [];
  String? _selectedCategory;

  List<CommodityPrice> get commodities => _commodities;
  CommodityPriceDetail? get selectedCommodity => _selectedCommodity;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;

  Future<void> loadCommodities({
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.getCommodityPrices(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      _commodities = response.data;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _commodities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCommodityDetail(String commodityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final detail = await _service.getCommodityPriceDetail(commodityId);
      _selectedCommodity = detail;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _selectedCommodity = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _service.getCategories();
      _categories = categories;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCommodity = null;
    notifyListeners();
  }
}

