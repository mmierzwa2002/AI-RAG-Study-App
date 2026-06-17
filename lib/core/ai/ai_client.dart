import 'dart:typed_data';

/// Jedna tura rozmowy wysyłana do modelu.
class ChatTurn {
  const ChatTurn({required this.role, required this.text});

  const ChatTurn.user(this.text) : role = 'user';

  const ChatTurn.assistant(this.text) : role = 'assistant';

  final String role; // 'user' | 'assistant'
  final String text;
}

/// Abstrakcja nad dostawcą AI — aplikacja nie wie, czy rozmawia
/// z Claude (Anthropic), czy z GPT (OpenAI).
abstract class AiClient {
  /// Strumieniowa odpowiedź czatu (SSE) — kolejne fragmenty tekstu.
  Stream<String> streamChat({
    required String system,
    required List<ChatTurn> turns,
    int maxTokens = 2048,
  });

  /// Pojedyncza, niestrumieniowa odpowiedź (fiszki, quizy itd.).
  Future<String> generate({
    required String system,
    required String prompt,
    int maxTokens = 4096,
  });

  /// Transkrypcja zdjęcia notatek przy użyciu modelu z obsługą obrazu.
  Future<String> transcribeImage({
    required Uint8List bytes,
    required String mimeType,
  });
}
