import 'dart:math' as math;

/// Fragment materiału przechowywany w "bazie wiedzy" przedmiotu.
class ChunkDoc {
  const ChunkDoc({
    required this.materialId,
    required this.source,
    required this.text,
  });

  factory ChunkDoc.fromJson(Map<String, dynamic> json) => ChunkDoc(
        materialId: json['materialId'] as String? ?? '',
        source: json['source'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  final String materialId;

  /// Nazwa pliku, z którego pochodzi fragment.
  final String source;
  final String text;

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'source': source,
        'text': text,
      };
}

/// Druga połowa uproszczonego RAG-a: wybór fragmentów najlepiej pasujących
/// do pytania użytkownika przy pomocy prostego TF-IDF (bez embeddingów,
/// bez zewnętrznych zależności).
class SimpleRetriever {
  const SimpleRetriever._();

  static final RegExp _splitter = RegExp(r'[^a-z0-9ąćęłńóśźż]+');

  static List<String> _tokens(String text) => text
      .toLowerCase()
      .split(_splitter)
      .where((t) => t.length > 2)
      .toList();

  /// Zwraca fragmenty najlepiej pasujące do [query].
  /// Gdy zapytanie nie pasuje do niczego (np. "streść mi materiał"),
  /// zwraca fragmenty w naturalnej kolejności.
  static List<ChunkDoc> topChunks({
    required String query,
    required List<ChunkDoc> chunks,
    int maxChunks = 5,
    int maxChars = 6000,
  }) {
    if (chunks.isEmpty) return [];

    final queryTerms = _tokens(query).toSet();
    final docTokens = chunks.map((c) => _tokens(c.text)).toList();

    // Document frequency — w ilu fragmentach występuje dany term.
    final df = <String, int>{};
    for (final tokens in docTokens) {
      for (final term in tokens.toSet()) {
        df[term] = (df[term] ?? 0) + 1;
      }
    }

    final n = chunks.length;
    final scored = <(int, double)>[];
    for (var i = 0; i < chunks.length; i++) {
      var score = 0.0;
      for (final term in queryTerms) {
        final tf = docTokens[i].where((t) => t == term).length;
        if (tf == 0) continue;
        final idf = math.log((n + 1) / ((df[term] ?? 0) + 1)) + 1;
        score += tf * idf;
      }
      scored.add((i, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    final ordered = scored.first.$2 <= 0
        ? List<int>.generate(chunks.length, (i) => i)
        : scored.map((s) => s.$1).toList();

    final result = <ChunkDoc>[];
    var chars = 0;
    for (final i in ordered) {
      final c = chunks[i];
      if (result.isNotEmpty &&
          (result.length >= maxChunks || chars + c.text.length > maxChars)) {
        break;
      }
      result.add(c);
      chars += c.text.length;
    }
    return result;
  }

  /// Losowa, ale równomiernie pokrywająca materiał próbka fragmentów —
  /// używana do generowania fiszek, quizów i pytań w trybie odpytywania.
  static List<ChunkDoc> sample({
    required List<ChunkDoc> chunks,
    int maxChars = 8000,
  }) {
    if (chunks.isEmpty) return [];
    final indices = List<int>.generate(chunks.length, (i) => i)..shuffle();
    final picked = <int>[];
    var chars = 0;
    for (final i in indices) {
      if (picked.isNotEmpty && chars + chunks[i].text.length > maxChars) {
        continue;
      }
      picked.add(i);
      chars += chunks[i].text.length;
      if (chars >= maxChars) break;
    }
    picked.sort();
    return picked.map((i) => chunks[i]).toList();
  }
}
