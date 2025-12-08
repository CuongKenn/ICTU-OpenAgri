import 'package:flutter/material.dart';

import '../models/chatbot_models.dart';
import '../services/chatbot_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel()
      : _messages = [
          const ChatMessage(
            role: ChatMessageRole.assistant,
            content:
                'Xin chào! Tôi là trợ lý nông nghiệp thông minh của bạn. Hãy cho tôi biết bạn đang canh tác cây gì hoặc gặp vấn đề gì để tôi hỗ trợ nhé.',
          ),
        ];

  final ChatbotService _service = ChatbotService();

  final List<ChatMessage> _messages;
  bool _isSending = false;
  String? _error;
  bool _isPanelOpen = false;
  int _failedAttempts = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get error => _error;
  bool get isPanelOpen => _isPanelOpen;
  int get failedAttempts => _failedAttempts;

  void togglePanel() {
    _isPanelOpen = !_isPanelOpen;
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage(String question) async {
    if (_isSending || question.trim().isEmpty) {
      return;
    }

    _error = null;
    _isSending = true;
    final trimmedQuestion = question.trim();
    _messages.add(
      ChatMessage(role: ChatMessageRole.user, content: trimmedQuestion),
    );
    notifyListeners();

    try {
      final reply = await _service.sendMessage(
        question: trimmedQuestion,
        history: _messages.sublist(0, _messages.length - 1),
      );
      _messages.add(reply);
      _failedAttempts = 0;  // Reset failed attempts on success
    } catch (error) {
      _failedAttempts++;
      _error = error.toString();
      
      // Add error message to chat history
      _messages.add(
        ChatMessage(
          role: ChatMessageRole.assistant,
          content:
              'Xin lỗi, tôi gặp sự cố khi xử lý yêu cầu: $_error\n\nVui lòng thử lại hoặc kiểm tra kết nối mạng.',
        ),
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void closePanel() {
    if (_isPanelOpen) {
      _isPanelOpen = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
  
  void clearChat() {
    _messages.clear();
    _messages.add(
      const ChatMessage(
        role: ChatMessageRole.assistant,
        content:
            'Xin chào! Tôi là trợ lý nông nghiệp thông minh của bạn. Hãy cho tôi biết bạn đang canh tác cây gì hoặc gặp vấn đề gì để tôi hỗ trợ nhé.',
      ),
    );
    _error = null;
    _failedAttempts = 0;
    notifyListeners();
  }
}
