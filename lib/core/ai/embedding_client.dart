/// Abstrakcja nad dostawcą embeddingów (wektorów).
///
/// Embedding to zamiana tekstu na listę liczb (wektor) opisującą jego
/// znaczenie. To pierwszy element "bazy wektorowej" w RAG: indeksujemy
/// fragmenty materiałów jako wektory, a potem szukamy tych najbliższych
/// pytaniu użytkownika.
///
/// Aplikacja nie wie, czy wektory liczy OpenAI, Gemini, czy lokalna Ollama.
abstract class EmbeddingClient {
  /// Zwraca wektor dla każdego tekstu wejściowego, w tej samej kolejności.
  Future<List<List<double>>> embed(List<String> texts);
}
