/// Dzieli wyekstrahowany tekst materiału na zachodzące na siebie fragmenty
/// ("chunki") — to pierwsza połowa uproszczonego RAG-a.
class TextChunker {
  const TextChunker._();

  static List<String> chunk(
    String text, {
    int chunkSize = 1200,
    int overlap = 200,
  }) {
    final clean = text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (clean.isEmpty) return [];
    if (clean.length <= chunkSize) return [clean];

    final chunks = <String>[];
    var start = 0;
    while (start < clean.length) {
      var end = start + chunkSize;
      if (end >= clean.length) {
        end = clean.length;
      } else {
        // Staraj się ciąć na granicy zdania lub akapitu.
        final breakAt = clean.lastIndexOf(RegExp(r'[.!?\n]'), end);
        if (breakAt > start + chunkSize ~/ 2) {
          end = breakAt + 1;
        }
      }
      final piece = clean.substring(start, end).trim();
      if (piece.isNotEmpty) chunks.add(piece);
      if (end >= clean.length) break;
      start = end - overlap;
    }
    return chunks;
  }
}
