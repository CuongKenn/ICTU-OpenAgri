import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseScanViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _hasResult = false;
  double _analysisProgress = 0.0;
  Map<String, dynamic>? _analysisResult;

  // Getters
  File? get selectedImage => _selectedImage;
  bool get isAnalyzing => _isAnalyzing;
  bool get hasResult => _hasResult;
  double get analysisProgress => _analysisProgress;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        _hasResult = false;
        _analysisResult = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void clearImage() {
    _selectedImage = null;
    _hasResult = false;
    _analysisResult = null;
    notifyListeners();
  }

  Future<void> analyzeImage() async {
    if (_selectedImage == null) return;

    _isAnalyzing = true;
    _hasResult = false;
    _analysisProgress = 0.0;
    notifyListeners();

    // Simulate analysis progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 150));
      _analysisProgress = i / 100;
      notifyListeners();
    }

    // Mock ML result (replace with actual ML model API call)
    await Future.delayed(const Duration(milliseconds: 500));

    _isAnalyzing = false;
    _hasResult = true;
    _analysisResult = {
      'disease_name': 'Đạo ôn lúa',
      'confidence': 0.98,
      'severity': 'Trung bình',
      'description':
          'Đạo ôn lúa là bệnh do nấm Pyricularia oryzae gây ra, thường xuất hiện khi độ ẩm cao và nhiệt độ từ 25-28°C.',
      'symptoms': [
        'Lá có các đốm màu nâu, hình thoi',
        'Đốm lan rộng và làm lá chết',
        'Cổ bông bị gãy, hạt lép',
      ],
      'treatment': [
        'Phun thuốc Tricyclazole 75% WP (3-4g/lít nước)',
        'Sử dụng Isoprothiolane 40% EC',
        'Tăng cường thông thoáng ruộng',
        'Bón phân cân đối, tránh bón quá nhiều đạm',
      ],
      'prevention': [
        'Chọn giống kháng bệnh',
        'Luân canh cây trồng',
        'Làm sạch cỏ dại và tàn dư cây trồng',
        'Quản lý nước tưới hợp lý',
      ],
    };
    notifyListeners();
  }
}
