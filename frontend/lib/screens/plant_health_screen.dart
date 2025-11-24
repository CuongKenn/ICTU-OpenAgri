import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_navigation_bar.dart';

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({super.key});

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _hasResult = false;
  double _analysisProgress = 0.0;
  late AnimationController _animationController;

  // Mock result data (will be replaced with real ML model results)
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasResult = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _hasResult = false;
      _analysisProgress = 0.0;
    });

    // Simulate analysis progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _analysisProgress = i / 100;
        });
      }
    }

    // Mock ML result (replace with actual ML model API call)
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: const AppNavigationBar(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildUploadSection(),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 24),
                      _buildImagePreview(),
                    ],
                    if (_isAnalyzing) ...[
                      const SizedBox(height: 32),
                      _buildAnalysisSection(),
                    ],
                    if (_hasResult && _analysisResult != null) ...[
                      const SizedBox(height: 32),
                      _buildResultSection(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0BDA50),
            Color(0xFF059669),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0BDA50).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.eco,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Giám sát sức khỏe cây trồng',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Phát hiện bệnh tật bằng trí tuệ nhân tạo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: Color(0xFF0BDA50),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tải lên ảnh cây trồng để phân tích bệnh tật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111813),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Chụp ảnh rõ nét lá, thân hoặc trái cây để được kết quả chính xác',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Chọn ảnh',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Chụp ảnh',
                  onPressed: () => _pickImage(ImageSource.camera),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFF0BDA50), Color(0xFF059669)],
                  )
                : null,
            color: isPrimary ? null : const Color(0xFFF0F5F1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? Colors.transparent : const Color(0xFF0BDA50),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF0BDA50),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.white : const Color(0xFF0BDA50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _hasResult = false;
                      _analysisResult = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Hủy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  icon: const Icon(Icons.analytics_outlined, size: 20),
                  label: const Text('Phân tích ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0BDA50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _animationController,
                  child: CircularProgressIndicator(
                    value: null,
                    strokeWidth: 8,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0BDA50),
                    ),
                  ),
                ),
                Text(
                  '${(_analysisProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0BDA50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang phân tích bệnh tật',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111813),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chờ chút, hệ thống sẽ trả về kết quả chính xác nhất',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    final result = _analysisResult!;
    final confidence = (result['confidence'] * 100).toInt();

    return Column(
      children: [
        // Disease Detection Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getSeverityColor(result['severity']).withValues(alpha: 0.1),
                _getSeverityColor(result['severity']).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getSeverityColor(result['severity']),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(result['severity'])
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: _getSeverityColor(result['severity']),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bệnh tật phát hiện',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF608a6e),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result['disease_name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111813),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Độ chính xác',
                      '$confidence%',
                      Icons.verified,
                      const Color(0xFF0BDA50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Mức độ',
                      result['severity'],
                      Icons.insights,
                      _getSeverityColor(result['severity']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Description Card
        _buildInfoCard(
          title: 'Mô tả bệnh',
          icon: Icons.description_outlined,
          content: result['description'],
        ),
        const SizedBox(height: 16),

        // Symptoms Card
        _buildListCard(
          title: 'Triệu chứng',
          icon: Icons.coronavirus_outlined,
          items: List<String>.from(result['symptoms']),
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),

        // Treatment Card
        _buildListCard(
          title: 'Cách điều trị',
          icon: Icons.medical_services_outlined,
          items: List<String>.from(result['treatment']),
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),

        // Prevention Card
        _buildListCard(
          title: 'Biện pháp phòng ngừa',
          icon: Icons.shield_outlined,
          items: List<String>.from(result['prevention']),
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _selectedImage = null;
              _hasResult = false;
              _analysisResult = null;
            });
          },
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('Phân tích ảnh khác'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0BDA50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF608a6e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0BDA50), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111813),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111813),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'cao':
      case 'nghiêm trọng':
        return const Color(0xFFEF4444);
      case 'trung bình':
        return const Color(0xFFFBBF24);
      case 'thấp':
      case 'nhẹ':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF608a6e);
    }
  }
}

