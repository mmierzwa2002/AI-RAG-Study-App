import 'dart:math' as math;

import 'simple_retriever.dart';

/// Wyszukiwanie wektorowe (druga połowa "bazy wektorowej" w RAG).
///
/// Mając wektor pytania i wektory fragmentów, liczymy cosine similarity
/// (podobieństwo kątowe między wektorami) i zwracamy fragmenty najbardziej
/// zbliżone znaczeniowo do pytania. To dokładniejsze niż dopasowanie po
/// słowach kluczowych (TF-IDF), bo łapie synonimy i parafrazy.
class VectorRetriever {
  const VectorRetriever._();

  /// Zwraca fragmenty najbliższe [queryEmbedding] w przestrzeni wektorowej.
  ///
  /// Pomija fragmenty bez wektora oraz o innej długości wektora niż pytanie
  /// (gdyby ktoś zmienił model embeddingów po zaindeksowaniu materiału).
  /// Gdy żaden fragment nie ma pasującego wektora, zwraca pustą listę,
  /// a warstwa wyżej powinna wpaść w fallback na TF-IDF.
  static List<ChunkDoc> topChunks({
    required List<double> queryEmbedding,
    required List<ChunkDoc> chunks,
    int maxChunks = 5,
    int maxChars = 6000,
  }) {
    if (queryEmbedding.isEmpty || chunks.isEmpty) return const [];

    final dim = queryEmbedding.length;
    final scored = <(int, double)>[];
    for (var i = 0; i < chunks.length; i++) {
      final embedding = chunks[i].embedding;
      if (embedding.length != dim) continue;
      scored.add((i, _cosine(queryEmbedding, embedding)));
    }
    if (scored.isEmpty) return const [];

    scored.sort((a, b) => b.$2.compareTo(a.$2));

    final result = <ChunkDoc>[];
    var chars = 0;
    for (final (index, _) in scored) {
      final chunk = chunks[index];
      if (result.isNotEmpty &&
          (result.length >= maxChunks ||
              chars + chunk.text.length > maxChars)) {
        break;
      }
      result.add(chunk);
      chars += chunk.text.length;
    }
    return result;
  }

  /// Cosine similarity: iloczyn skalarny podzielony przez iloczyn długości.
  /// Wynik w zakresie [-1, 1], gdzie 1 to identyczny kierunek (pełne
  /// podobieństwo znaczeniowe).
  static double _cosine(List<double> a, List<double> b) {
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }
}
