import '../../../core/ai/ai_client.dart';
import '../../../core/ai/ai_client_factory.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/simple_retriever.dart';
import '../../../core/utils/vector_retriever.dart';
import '../../materials/domain/material_repository.dart';
import '../../subjects/domain/subject.dart';
import 'chat_message.dart';

/// Główny use case czatu: buduje kontekst RAG z materiałów przedmiotu,
/// składa prompt systemowy (zwykły lub egzaminacyjny) i zwraca
/// strumieniową odpowiedź modelu.
class SendChatMessage {
  SendChatMessage({
    required MaterialRepository materials,
    required AiClientFactory aiFactory,
  })  : _materials = materials,
        _aiFactory = aiFactory;

  final MaterialRepository _materials;
  final AiClientFactory _aiFactory;

  Stream<String> call({
    required Subject subject,
    required List<ChatMessage> history,
    required bool examMode,
  }) async* {
    final ai = await _aiFactory.create();
    final chunks = await _materials.getChunks(subject.id);

    if (examMode && chunks.isEmpty) {
      throw const AppException(
        'Brak materiałów do odpytywania. Dodaj najpierw PDF lub zdjęcie '
        'notatek w zakładce „Materiały”.',
      );
    }

    if (history.isEmpty) {
      throw const AppException('Brak wiadomości do wysłania.');
    }
    final lastUserText =
        history.lastWhere((m) => m.isUser, orElse: () => history.last).text;

    // RAG: w zwykłym czacie wybieramy fragmenty pasujące do pytania
    // (wyszukiwanie wektorowe, z fallbackiem na TF-IDF), a w trybie
    // odpytywania bierzemy próbkę całego materiału.
    final selected = examMode
        ? SimpleRetriever.sample(chunks: chunks, maxChars: 7000)
        : await _retrieve(lastUserText, chunks);

    final system = examMode
        ? _examSystemPrompt(subject.name, selected)
        : _chatSystemPrompt(subject.name, selected);

    final turns = _toTurns(history);
    if (turns.isEmpty) {
      throw const AppException('Brak wiadomości do wysłania.');
    }

    yield* ai.streamChat(system: system, turns: turns);
  }

  /// Wybiera fragmenty najlepiej pasujące do pytania. Najpierw próbuje
  /// wyszukiwania wektorowego (embedding pytania + cosine similarity wobec
  /// "bazy wektorowej"), a gdy to niedostępne (dostawca bez embeddingów,
  /// fragmenty bez wektorów albo błąd sieci) spada na TF-IDF. Dzięki temu
  /// czat działa zawsze, niezależnie od konfiguracji.
  Future<List<ChunkDoc>> _retrieve(String query, List<ChunkDoc> chunks) async {
    final hasVectors = chunks.any((c) => c.embedding.isNotEmpty);
    if (hasVectors) {
      try {
        final embedder = await _aiFactory.createEmbedding();
        if (embedder != null) {
          final queryEmbedding = (await embedder.embed([query])).first;
          final byVector = VectorRetriever.topChunks(
            queryEmbedding: queryEmbedding,
            chunks: chunks,
          );
          if (byVector.isNotEmpty) return byVector;
        }
      } catch (_) {
        // Po cichu spadamy na TF-IDF poniżej.
      }
    }
    return SimpleRetriever.topChunks(query: query, chunks: chunks);
  }

  /// Mapuje historię na tury API: ostatnie 16 wiadomości, zaczynając od
  /// wiadomości użytkownika i scalając sąsiednie wiadomości tej samej roli.
  List<ChatTurn> _toTurns(List<ChatMessage> history) {
    final recent = history.length > 16
        ? history.sublist(history.length - 16)
        : List.of(history);
    while (recent.isNotEmpty && !recent.first.isUser) {
      recent.removeAt(0);
    }
    final turns = <ChatTurn>[];
    for (final message in recent) {
      final turn = message.isUser
          ? ChatTurn.user(message.text)
          : ChatTurn.assistant(message.text);
      if (turns.isNotEmpty && turns.last.role == turn.role) {
        final previous = turns.removeLast();
        turns.add(
          ChatTurn(role: turn.role, text: '${previous.text}\n\n${turn.text}'),
        );
      } else {
        turns.add(turn);
      }
    }
    return turns;
  }

  String _renderChunks(List<ChunkDoc> chunks) => chunks
      .map((c) => '[Źródło: ${c.source}]\n${c.text}')
      .join('\n\n---\n\n');

  String _chatSystemPrompt(String subjectName, List<ChunkDoc> chunks) {
    final materialsSection = chunks.isEmpty
        ? 'Student nie dodał jeszcze żadnych materiałów do tego przedmiotu. '
            'Zachęć go do dodania PDF-a lub zdjęcia notatek w zakładce '
            '„Materiały” i odpowiadaj z wiedzy ogólnej.'
        : 'FRAGMENTY MATERIAŁÓW STUDENTA:\n${_renderChunks(chunks)}';
    return 'Jesteś asystentem nauki. Pomagasz studentowi zrozumieć materiał '
        'z przedmiotu „$subjectName”.\n\n'
        'Zasady:\n'
        '- Odpowiadaj po polsku, zwięźle i konkretnie, jak dobry korepetytor.\n'
        '- Opieraj się przede wszystkim na fragmentach materiałów poniżej.\n'
        '- Jeśli w materiałach nie ma odpowiedzi, powiedz to wprost i dopiero '
        'wtedy odpowiedz z wiedzy ogólnej.\n'
        '- Pisz zwykłym tekstem, bez formatowania Markdown.\n\n'
        '$materialsSection';
  }

  String _examSystemPrompt(String subjectName, List<ChunkDoc> chunks) {
    return 'Jesteś życzliwym, ale wymagającym egzaminatorem z przedmiotu '
        '„$subjectName”. Odpytujesz studenta wyłącznie z poniższych '
        'materiałów.\n\n'
        'Zasady odpytywania:\n'
        '- Zadawaj JEDNO pytanie naraz i czekaj na odpowiedź studenta.\n'
        '- Po każdej odpowiedzi oceń ją (poprawna / częściowo poprawna / '
        'błędna), w 1–3 zdaniach wyjaśnij, czego brakowało, podaj poprawną '
        'odpowiedź, a następnie zadaj kolejne pytanie.\n'
        '- Zaczynaj od prostszych pytań i stopniowo zwiększaj trudność.\n'
        '- Co 4–5 pytań krótko podsumuj, jak idzie studentowi.\n'
        '- Odpowiadaj po polsku, zwykłym tekstem, bez formatowania Markdown.\n\n'
        'MATERIAŁY:\n${_renderChunks(chunks)}';
  }
}
