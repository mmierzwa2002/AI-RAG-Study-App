import 'chat_message.dart';

abstract class ChatRepository {
  /// Historia rozmowy danego przedmiotu (rosnąco po dacie).
  Future<List<ChatMessage>> getMessages(String subjectId);

  Future<void> save(ChatMessage message);

  Future<void> clear(String subjectId);
}
