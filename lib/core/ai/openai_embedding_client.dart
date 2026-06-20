import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/app_exception.dart';
import 'embedding_client.dart';

/// Klient embeddingów w formacie OpenAI (`POST {baseUrl}/embeddings`).
///
/// Dzięki konfigurowalnemu [baseUrl] obsługuje też darmowe i lokalne
/// alternatywy zgodne z tym formatem:
///  - OpenAI: model np. text-embedding-3-small,
///  - Google Gemini (warstwa OpenAI-compat): np. text-embedding-004,
///  - lokalna Ollama (http://localhost:11434/v1): np. nomic-embed-text.
class OpenAiEmbeddingClient implements EmbeddingClient {
  OpenAiEmbeddingClient({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
    required http.Client httpClient,
  }) : _http = httpClient;

  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _http;

  Uri get _endpoint {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.parse('$base/embeddings');
  }

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        // Lokalna Ollama nie wymaga klucza, wtedy nagłówek pomijamy.
        if (apiKey.isNotEmpty) 'authorization': 'Bearer $apiKey',
      };

  @override
  Future<List<List<double>>> embed(List<String> texts) async {
    if (texts.isEmpty) return const [];

    final response = await _http.post(
      _endpoint,
      headers: _headers,
      body: jsonEncode({'model': model, 'input': texts}),
    );
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw AiException(_errorFromBody(response.statusCode, body));
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'];
    if (data is! List) {
      throw const AiException('Embeddings: nieoczekiwana odpowiedź API.');
    }
    // Odpowiedź zwykle jest już w kolejności wejścia, ale dla pewności
    // sortujemy po polu "index", gdy występuje.
    final items = data.whereType<Map>().toList()
      ..sort((a, b) =>
          ((a['index'] as num?) ?? 0).compareTo((b['index'] as num?) ?? 0));
    return items.map((item) {
      final vector = item['embedding'];
      if (vector is! List) {
        throw const AiException('Embeddings: brak wektora w odpowiedzi.');
      }
      return vector.map((e) => (e as num).toDouble()).toList();
    }).toList();
  }

  String _errorFromBody(int status, String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'];
      final message = error is Map ? error['message'] : null;
      if (message is String) return 'Embeddings API ($status): $message';
    } catch (_) {}
    return 'Embeddings API ($status): $body';
  }
}
