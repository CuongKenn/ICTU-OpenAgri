// Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
// Licensed under the MIT License. See LICENSE file in the project root for full license information.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/api_models.dart';
import '../services/analysis_service.dart';

class DiseaseScanViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final AnalysisService _analysisService = AnalysisService();

  XFile? _selectedImage;
  bool _isAnalyzing = false;
  bool _hasResult = false;
  DiseasePredictionDTO? _analysisResult;
  String? _error;

  // Getters
  XFile? get selectedImage => _selectedImage;
  bool get isAnalyzing => _isAnalyzing;
  bool get hasResult => _hasResult;
  DiseasePredictionDTO? get analysisResult => _analysisResult;
  String? get error => _error;

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = image;
        _hasResult = false;
        _analysisResult = null;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _error = 'Không thể chọn ảnh: $e';
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImage = null;
    _hasResult = false;
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }

  Future<void> analyzeImage() async {
    if (_selectedImage == null) return;

    _isAnalyzing = true;
    _hasResult = false;
    _error = null;
    notifyListeners();

    try {
      final result = await _analysisService.predictDisease(_selectedImage!);
      _analysisResult = result;
      _hasResult = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error analyzing image: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
}
