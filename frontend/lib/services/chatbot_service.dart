import 'package:dio/dio.dart';

import '../models/chatbot_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ChatbotService {
  ChatbotService()
      : _apiService = ApiService(),
        _authService = AuthService();

  final ApiService _apiService;
  final AuthService _authService;
  
  static const int _maxRetries = 2;
  static const Duration _timeout = Duration(seconds: 30);

  Future<ChatMessage> sendMessage({
    required String question,
    required List<ChatMessage> history,
  }) async {
    // Validate input
    if (question.trim().isEmpty) {
      throw Exception('Câu hỏi không được để trống.');
    }
    
    if (question.trim().length > 1000) {
      throw Exception('Câu hỏi không được vượt quá 1000 ký tự.');
    }
    
    if (question.trim().length < 3) {
      throw Exception('Câu hỏi quá ngắn. Vui lòng viết chi tiết hơn.');
    }

    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Bạn cần đăng nhập để sử dụng trợ lý AI.');
    }

    final formattedHistory = history
        .map((message) => {
              'role': message.role == ChatMessageRole.assistant
                  ? 'assistant'
                  : 'user',
              'content': message.content,
            })
        .toList();

    // Implement retry logic
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _apiService.client.post(
          '/chatbot/chat',
          data: {
            'question': question,
            'history': formattedHistory,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
            sendTimeout: _timeout,
            receiveTimeout: _timeout,
          ),
        );

        final data = response.data as Map<String, dynamic>;
        final tipsJson = (data['tips'] as List<dynamic>? ?? [])
            .map((tipJson) => ChatTip.fromJson(tipJson as Map<String, dynamic>))
            .toList();

        return ChatMessage(
          role: ChatMessageRole.assistant,
          content: data['answer']?.toString() ?? '',
          tips: tipsJson,
        );
      } on DioException catch (error) {
        final status = error.response?.statusCode ?? 500;
        
        // Don't retry on client errors (400-499)
        if (status >= 400 && status < 500) {
          final defaultMessage = 'Không thể kết nối tới trợ lý AI.';
          final detail = error.response?.data is Map<String, dynamic>
              ? (error.response?.data['detail']?.toString() ?? defaultMessage)
              : defaultMessage;

          if (status == 400) {
            throw Exception('Yêu cầu không hợp lệ: $detail');
          }
          if (status == 401) {
            throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
          }
          throw Exception(detail);
        }

        // Retry on server errors (500+) or network errors
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }

        // Final attempt failed
        if (status == 503) {
          throw Exception('Trợ lý AI đang bận. Vui lòng thử lại sau.');
        }
        
        final defaultMessage = 'Không thể kết nối tới trợ lý AI. Vui lòng thử lại.';
        if (error.response == null) {
          throw Exception(defaultMessage);
        }

        final detail = error.response?.data is Map<String, dynamic>
            ? (error.response?.data['detail']?.toString() ?? defaultMessage)
            : defaultMessage;
        throw Exception(detail);
      } catch (error) {
        // Retry on generic errors (network issues, etc.)
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        throw Exception(error.toString());
      }
    }
    
    // Should never reach here
    throw Exception('Không thể gửi yêu cầu sau $_maxRetries lần thử.');
  }
}
