import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/soil_analysis_viewmodel.dart';
import '../models/soil_analysis_model.dart';

class SoilAnalysisScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final bool isDialog; // Flag to adjust UI for dialog mode

  const SoilAnalysisScreen({
    super.key, 
    this.initialLat, 
    this.initialLon,
    this.isDialog = false,
  });

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLon != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SoilAnalysisViewModel>().analyzeSoil(
              widget.initialLat!,
              widget.initialLon!,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG: Building SoilAnalysisScreen");
    return Consumer<SoilAnalysisViewModel>(
      builder: (context, viewModel, child) {
        print("DEBUG: SoilAnalysisViewModel state - isLoading: ${viewModel.isLoading}, result: ${viewModel.result}, error: ${viewModel.error}");
        if (widget.isDialog) {
           return _buildContent(viewModel);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Phân Tích Đất & Cây Trồng'),
            backgroundColor: Colors.white,
          ),
          body: _buildContent(viewModel),
        );
      },
    );
  }

  Widget _buildContent(SoilAnalysisViewModel viewModel) {
    print("DEBUG: _buildContent - isLoading: ${viewModel.isLoading}, error: ${viewModel.error}, result: ${viewModel.result}");
    
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang phân tích đất...'),
          ],
        ),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Lỗi: ${viewModel.error}', textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.initialLat != null && widget.initialLon != null) {
                  viewModel.analyzeSoil(widget.initialLat!, widget.initialLon!);
                }
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (viewModel.result == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    final result = viewModel.result!;
    final soil = result.soilProperties;

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
                  '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}'),
            ),
          ),
          const SizedBox(height: 16),

          // Soil Properties
          _buildSoilPropertiesCard(soil),
          const SizedBox(height: 16),

          // Recommendations
          const Text(
            'Đề Xuất Cây Trồng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRecommendationsList(result.cropRecommendations),
        ],
      ),
    );
  }

  Widget _buildSoilPropertiesCard(SoilProperties soil) {
    return Card(
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
                  color: Colors.brown),
            ),
            const Divider(),
            _buildPropertyRow('Độ pH (H2O)',
                soil.phWater?.toStringAsFixed(1) ?? 'N/A', Icons.science),
            _buildPropertyRow(
                'Hữu cơ (SOC)',
                '${soil.organicCarbon?.toStringAsFixed(1) ?? 'N/A'} g/kg',
                Icons.grass),
            _buildPropertyRow('Đạm (Nitrogen)',
                '${soil.nitrogen?.toStringAsFixed(2) ?? 'N/A'} g/kg', Icons.eco),
            _buildPropertyRow('Kết cấu', soil.soilTexture ?? 'N/A', Icons.layers),
            if (soil.sandPercent != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Cát: ${soil.sandPercent}% - Limon: ${soil.siltPercent}% - Sét: ${soil.clayPercent}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
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

  Widget _buildRecommendationsList(List<CropRecommendation> recommendations) {
    if (recommendations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Không tìm thấy cây trồng phù hợp cho loại đất này.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final crop = recommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getScoreColor(crop.suitabilityScore),
              child: Text(
                '${crop.suitabilityScore.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(crop.cropNameVi,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(crop.cropName),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (crop.reasons.isNotEmpty) ...[
                      const Text('Điểm mạnh:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green)),
                      ...crop.reasons
                          .map((r) => Text('• $r',
                              style: const TextStyle(fontSize: 13)))
                          ,
                      const SizedBox(height: 8),
                    ],
                    if (crop.warnings.isNotEmpty) ...[
                      const Text('Lưu ý:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.orange)),
                      ...crop.warnings
                          .map((w) => Text('• $w',
                              style: const TextStyle(fontSize: 13)))
                          ,
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
