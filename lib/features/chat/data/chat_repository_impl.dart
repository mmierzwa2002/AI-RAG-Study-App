import '../../../core/storage/json_storage.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import 'chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._storage);

  final JsonStorage _storage;

  String _key(String subjectId) => 'messages_$subjectId';

  @override
  Future<List<ChatMessage>> getMessages(String subjectId) async {
    final raw = await _storage.readList(_key(subjectId));
    final messages = raw.map(ChatMessageModel.fromJson).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  @override
  Future<void> save(ChatMessage message) async {
    final raw = await _storage.readList(_key(message.subjectId));
    raw.add(ChatMessageModel.fromEntity(message).toJson());
    await _storage.writeList(_key(message.subjectId), raw);
  }

  @override
  Future<void> clear(String subjectId) async {
    await _storage.deleteCollection(_key(subjectId));
  }
}
