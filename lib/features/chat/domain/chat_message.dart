import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.subjectId,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String subjectId;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  @override
  List<Object?> get props => [id, subjectId, role, text, createdAt];
}
