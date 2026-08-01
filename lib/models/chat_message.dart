import 'dart:convert';

enum ChatRole {
  user,
  assistant,
  system,
}

extension ChatRoleX on ChatRole {
  String get apiName {
    switch (this) {
      case ChatRole.user:
        return 'user';
      case ChatRole.assistant:
        return 'assistant';
      case ChatRole.system:
        return 'system';
    }
  }

  static ChatRole parse(String s) {
    switch (s) {
      case 'user':
        return ChatRole.user;
      case 'assistant':
        return ChatRole.assistant;
      default:
        return ChatRole.system;
    }
  }
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        role: ChatRoleX.parse(j['role'] as String),
        content: j['content'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        isError: (j['isError'] as bool?) ?? false,
      );

  String toRawJson() => jsonEncode(toJson());
  factory ChatMessage.fromRawJson(String s) =>
      ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
