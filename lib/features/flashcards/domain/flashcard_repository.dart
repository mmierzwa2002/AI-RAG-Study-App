import 'flashcard.dart';

abstract class FlashcardRepository {
  Future<List<Flashcard>> getForSubject(String subjectId);

  Future<void> addAll(List<Flashcard> cards);

  Future<void> delete({required String subjectId, required String cardId});

  Future<void> clear(String subjectId);
}
