import 'package:flutter/material.dart';
import '../models/soil_analysis_model.dart';
import '../services/soil_analysis_service.dart';

class SoilAnalysisDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String fieldName;

  const SoilAnalysisDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.fieldName,
  });

  @override
  State<SoilAnalysisDialog> createState() => _SoilAnalysisDialogState();
}

class _SoilAnalysisDialogState extends State<SoilAnalysisDialog> {
  final SoilAnalysisService _service = SoilAnalysisService();
  bool _isLoading = true;
  String? _error;
  SoilAnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.analyzeSoil(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );
      
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.science, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phân tích đất: ${widget.fieldName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0BDA50)),
            SizedBox(height: 16),
            Text('Đang phân tích đất...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Lỗi khi phân tích đất',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final soil = _result!.soilProperties;
    final recommendations = _result!.cropRecommendations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Info
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Vị trí phân tích'),
              subtitle: Text(
                '${_result!.latitude.toStringAsFixed(4)}, ${_result!.longitude.toStringAsFixed(4)}',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Soil Properties
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thuộc Tính Đất',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const Divider(),
                  _buildPropertyRow('Độ pH (H2O)', soil.phWater?.toStringAsFixed(1) ?? 'N/A', Icons.science),
                  _buildPropertyRow('Hữu cơ (SOC)', '${soil.organicCarbon?.toStringAsFixed(1) ?? 'N/A'} g/kg', Icons.grass),
                  _buildPropertyRow('Đạm (N)', '${soil.nitrogen?.toStringAsFixed(2) ?? 'N/A'} g/kg', Icons.eco),
                  _buildPropertyRow('Kết cấu', soil.soilTexture ?? 'N/A', Icons.layers),
                  if (soil.sandPercent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Cát: ${soil.sandPercent!.toStringAsFixed(1)}% - Limon: ${soil.siltPercent!.toStringAsFixed(1)}% - Sét: ${soil.clayPercent!.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recommendations
          const Text(
            'Đề Xuất Cây Trồng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          if (recommendations.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Không tìm thấy cây trồng phù hợp.'),
              ),
            )
          else
            ...recommendations.map((crop) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getScoreColor(crop.suitabilityScore),
                  child: Text(
                    '${crop.suitabilityScore.toInt()}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(crop.cropNameVi, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(crop.cropName),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (crop.reasons.isNotEmpty) ...[
                          const Text('Điểm mạnh:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ...crop.reasons.map((r) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text('• $r', style: const TextStyle(fontSize: 13)),
                          )),
                          const SizedBox(height: 8),
                        ],
                        if (crop.warnings.isNotEmpty) ...[
                          const Text('Lưu ý:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ...crop.warnings.map((w) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text('• $w', style: const TextStyle(fontSize: 13)),
                          )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
