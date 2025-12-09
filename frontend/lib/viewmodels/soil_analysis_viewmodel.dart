import 'package:flutter/foundation.dart';
import '../models/soil_analysis_model.dart';
import '../services/soil_analysis_service.dart';

class SoilAnalysisViewModel extends ChangeNotifier {
  final SoilAnalysisService _service = SoilAnalysisService();

  SoilAnalysisResult? _result;
  bool _isLoading = false;
  String? _error;

  SoilAnalysisResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> analyzeSoil(double lat, double lon) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _result = await _service.analyzeSoil(latitude: lat, longitude: lon);
    } catch (e) {
      _error = e.toString();
      _result = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}
