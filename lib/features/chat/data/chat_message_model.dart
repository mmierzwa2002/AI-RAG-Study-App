import '../domain/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.subjectId,
    required super.role,
    required super.text,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        text: json['text'] as String? ?? '',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      );

  factory ChatMessageModel.fromEntity(ChatMessage message) => ChatMessageModel(
        id: message.id,
        subjectId: message.subjectId,
        role: message.role,
        text: message.text,
        createdAt: message.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'role': role,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
