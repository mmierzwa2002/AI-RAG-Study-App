import '../../../core/ai/ai_client_factory.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/ai_json.dart';
import '../../../core/utils/simple_retriever.dart';
import '../../materials/domain/material_repository.dart';
import '../../subjects/domain/subject.dart';
import 'quiz_question.dart';

/// Generuje quiz jednokrotnego wyboru z materiałów przedmiotu.
class GenerateQuiz {
  GenerateQuiz({
    required MaterialRepository materials,
    required AiClientFactory aiFactory,
  })  : _materials = materials,
        _aiFactory = aiFactory;

  final MaterialRepository _materials;
  final AiClientFactory _aiFactory;

  Future<List<QuizQuestion>> call({
    required Subject subject,
    int count = 5,
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
      system: 'Układasz quizy sprawdzające wiedzę studenta. Zwracasz '
          'WYŁĄCZNIE poprawny JSON, bez żadnego dodatkowego tekstu i bez '
          'bloków kodu.',
      prompt: 'Na podstawie poniższych materiałów z przedmiotu '
          '„${subject.name}” ułóż $count pytań jednokrotnego wyboru po '
          'polsku.\n'
          'Każde pytanie ma dokładnie 4 odpowiedzi, z których dokładnie '
          'jedna jest poprawna. Pole "correctIndex" to indeks poprawnej '
          'odpowiedzi (0–3), a "explanation" to krótkie wyjaśnienie.\n'
          'Format odpowiedzi (tylko JSON):\n'
          '[{"question": "...", "options": ["...", "...", "...", "..."], '
          '"correctIndex": 0, "explanation": "..."}]\n\n'
          'MATERIAŁY:\n$materialText',
    );

    final parsed = extractJsonList(raw);
    final questions = <QuizQuestion>[];
    for (final item in parsed) {
      if (item is! Map) continue;
      final question = item['question'];
      final options = item['options'];
      final rawIndex = item['correctIndex'];
      final explanation = item['explanation'];
      if (question is! String || options is! List || rawIndex is! num) {
        continue;
      }
      final parsedOptions = options.whereType<String>().toList();
      final correctIndex = rawIndex.toInt();
      if (parsedOptions.length < 2 ||
          correctIndex < 0 ||
          correctIndex >= parsedOptions.length) {
        continue;
      }
      questions.add(QuizQuestion(
        question: question.trim(),
        options: parsedOptions,
        correctIndex: correctIndex,
        explanation: explanation is String ? explanation.trim() : '',
      ));
    }
    if (questions.isEmpty) {
      throw const AppException(
        'Nie udało się wygenerować quizu. Spróbuj ponownie.',
      );
    }
    return questions;
  }
}
