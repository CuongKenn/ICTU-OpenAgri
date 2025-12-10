import '../models/api_models.dart';
import 'api_service.dart';

class SoilService {
  final ApiService _apiService = ApiService();

  Future<List<SoilAnalysisModel>> getSoilData() async {
    final response = await _apiService.client.get('/soil/soil-data');
    final entities = response.data['entities'] as List<dynamic>? ?? [];
    return entities
        .map((e) => SoilAnalysisModel.fromNgsiEntity(e as Map<String, dynamic>))
        .toList();
  }
}

