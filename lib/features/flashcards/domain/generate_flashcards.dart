import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_client_factory.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/ai_json.dart';
import '../../../core/utils/simple_retriever.dart';
import '../../materials/domain/material_repository.dart';
import '../../subjects/domain/subject.dart';
import 'flashcard.dart';
import 'flashcard_repository.dart';

/// Generuje fiszki z materiałów przedmiotu: pobiera próbkę fragmentów,
/// prosi model o czysty JSON, waliduje go i zapisuje karty.
class GenerateFlashcards {
  GenerateFlashcards({
    required MaterialRepository materials,
    required FlashcardRepository flashcards,
    required AiClientFactory aiFactory,
  })  : _materials = materials,
        _flashcards = flashcards,
        _aiFactory = aiFactory;

  final MaterialRepository _materials;
  final FlashcardRepository _flashcards;
  final AiClientFactory _aiFactory;
  final _uuid = const Uuid();

  Future<List<Flashcard>> call({
    required Subject subject,
    int count = 10,
  }) async {
    final chunks = await _materials.getChunks(subject.id);
    if (chunks.isEmpty) {
      throw const AppException(
        'Najpierw dodaj materiały w zakładce „Materiały”.',
      );
    }
    final ai = await _aiFactory.create();
    final sampled = SimpleRetriever.sample(chunks: chunks, maxChars: 9000);
    final materialText =
        sampled.map((c) => '[${c.source}]\n${c.text}').join('\n\n');

    final raw = await ai.generate(
      system: 'Tworzysz fiszki do nauki dla studenta. Zwracasz WYŁĄCZNIE '
          'poprawny JSON, bez żadnego dodatkowego tekstu i bez bloków kodu.',
      prompt: 'Na podstawie poniższych materiałów z przedmiotu '
          '„${subject.name}” przygotuj $count fiszek po polsku.\n'
          'Przód fiszki to krótkie pytanie lub pojęcie, tył to zwięzła '
          'odpowiedź lub definicja (maksymalnie 2–3 zdania).\n'
          'Format odpowiedzi (tylko JSON):\n'
          '[{"front": "...", "back": "..."}]\n\n'
          'MATERIAŁY:\n$materialText',
    );

    final parsed = extractJsonList(raw);
    final now = DateTime.now();
    final cards = <Flashcard>[];
    for (final item in parsed) {
      if (item is! Map) continue;
      final front = item['front'];
      final back = item['back'];
      if (front is String &&
          back is String &&
          front.trim().isNotEmpty &&
          back.trim().isNotEmpty) {
        cards.add(Flashcard(
          id: _uuid.v4(),
          subjectId: subject.id,
          front: front.trim(),
          back: back.trim(),
          createdAt: now,
        ));
      }
    }
    if (cards.isEmpty) {
      throw const AppException(
        'Nie udało się wygenerować fiszek. Spróbuj ponownie.',
      );
    }
    await _flashcards.addAll(cards);
    return cards;
  }
}
