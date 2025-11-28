import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';

class DashboardViewModel extends ChangeNotifier {
  // State
  bool _isLoading = true;
  DashboardStats _stats = DashboardStats.getMockData();
  List<FieldStatus> _fields = [];
  List<ActivityLog> _activities = [];
  WeatherData _weather = WeatherData.getMockData();

  // Getters
  bool get isLoading => _isLoading;
  DashboardStats get stats => _stats;
  List<FieldStatus> get fields => _fields;
  List<ActivityLog> get activities => _activities;
  WeatherData get weather => _weather;

  // Initialize data
  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Load mock data
    // In a real app, these would be API calls
    _stats = DashboardStats.getMockData();
    _fields = FieldStatus.getMockList();
    _activities = ActivityLog.getMockList();
    _weather = WeatherData.getMockData();

    _isLoading = false;
    notifyListeners();
  }

  // Refresh data
  Future<void> refreshData() async {
    await initData();
  }
}
