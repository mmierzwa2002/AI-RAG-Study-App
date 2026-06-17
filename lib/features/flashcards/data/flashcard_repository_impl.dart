import '../../../core/storage/json_storage.dart';
import '../domain/flashcard.dart';
import '../domain/flashcard_repository.dart';
import 'flashcard_model.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  FlashcardRepositoryImpl(this._storage);

  final JsonStorage _storage;

  String _key(String subjectId) => 'flashcards_$subjectId';

  @override
  Future<List<Flashcard>> getForSubject(String subjectId) async {
    final raw = await _storage.readList(_key(subjectId));
    return raw.map(FlashcardModel.fromJson).toList();
  }

  @override
  Future<void> addAll(List<Flashcard> cards) async {
    if (cards.isEmpty) return;
    final subjectId = cards.first.subjectId;
    final raw = await _storage.readList(_key(subjectId));
    raw.addAll(cards.map((c) => FlashcardModel.fromEntity(c).toJson()));
    await _storage.writeList(_key(subjectId), raw);
  }

  @override
  Future<void> delete({
    required String subjectId,
    required String cardId,
  }) async {
    final raw = await _storage.readList(_key(subjectId));
    raw.removeWhere((e) => e['id'] == cardId);
    await _storage.writeList(_key(subjectId), raw);
  }

  @override
  Future<void> clear(String subjectId) async {
    await _storage.deleteCollection(_key(subjectId));
  }
}
