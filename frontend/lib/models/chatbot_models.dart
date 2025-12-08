import 'package:flutter/foundation.dart';

enum ChatMessageRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage({required this.role, required this.content, this.tips});

  final ChatMessageRole role;
  final String content;
  final List<ChatTip>? tips;

  ChatMessage copyWith({
    ChatMessageRole? role,
    String? content,
    List<ChatTip>? tips,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      tips: tips ?? this.tips,
    );
  }
}

@immutable
class ChatTip {
  const ChatTip({required this.id, required this.title, required this.summary});

  final String id;
  final String title;
  final String summary;

  factory ChatTip.fromJson(Map<String, dynamic> json) {
    return ChatTip(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
    );
  }
}
