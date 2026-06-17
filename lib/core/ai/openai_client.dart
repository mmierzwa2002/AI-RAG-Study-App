import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../error/app_exception.dart';
import 'ai_client.dart';
import 'sse.dart';

/// Klient API w formacie OpenAI Chat Completions.
///
/// Dzięki konfigurowalnemu [baseUrl] działa też z darmowymi alternatywami
/// zgodnymi z tym formatem: Google Gemini, Groq, OpenRouter, Ollama.
class OpenAiClient implements AiClient {
  OpenAiClient({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
    required http.Client httpClient,
  }) : _http = httpClient;

  final String apiKey;
  final String model;

  /// Np. https://api.openai.com/v1, https://api.groq.com/openai/v1,
  /// https://generativelanguage.googleapis.com/v1beta/openai,
  /// http://localhost:11434/v1 (Ollama).
  final String baseUrl;
  final http.Client _http;

  Uri get _endpoint {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.parse('$base/chat/completions');
  }

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        // Lokalna Ollama nie wymaga klucza — wtedy nagłówek pomijamy.
        if (apiKey.isNotEmpty) 'authorization': 'Bearer $apiKey',
      };

  @override
  Stream<String> streamChat({
    required String system,
    required List<ChatTurn> turns,
    int maxTokens = 2048,
  }) async* {
    final request = http.Request('POST', _endpoint)
      ..headers.addAll(_headers)
      ..body = jsonEncode({
        'model': model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': system},
          for (final t in turns) {'role': t.role, 'content': t.text},
        ],
      });

    final response = await _http.send(request);
    if (response.statusCode != 200) {
      throw AiException(_errorFromBody(
        response.statusCode,
        await response.stream.bytesToString(),
      ));
    }

    await for (final data in sseDataLines(response)) {
      if (data.isEmpty) continue;
      if (data == '[DONE]') return;
      Map<String, dynamic> event;
      try {
        event = jsonDecode(data) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      if (event['error'] != null) {
        final error = event['error'];
        final message = error is Map ? error['message'] : null;
        throw AiException('Błąd API OpenAI: ${message ?? data}');
      }
      final choices = event['choices'];
      if (choices is List && choices.isNotEmpty) {
        final delta = (choices.first as Map)['delta'];
        final content = delta is Map ? delta['content'] : null;
        if (content is String && content.isNotEmpty) yield content;
      }
    }
  }

  @override
  Future<String> generate({
    required String system,
    required String prompt,
    int maxTokens = 4096,
  }) async {
    final json = await _post({
      'model': model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': prompt},
      ],
    });
    return _messageContent(json);
  }

  @override
  Future<String> transcribeImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final json = await _post({
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Przepisz dokładnie cały tekst widoczny na tym zdjęciu '
                  'notatek. Zachowaj strukturę (nagłówki, listy), a wzory '
                  'i symbole zapisz tekstowo. Zwróć wyłącznie przepisany '
                  'tekst, bez żadnych komentarzy.',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,${base64Encode(bytes)}',
              },
            },
          ],
        },
      ],
    });
    return _messageContent(json);
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final response =
        await _http.post(_endpoint, headers: _headers, body: jsonEncode(body));
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw AiException(_errorFromBody(response.statusCode, text));
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  String _messageContent(Map<String, dynamic> json) {
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = (choices.first as Map)['message'];
      final content = message is Map ? message['content'] : null;
      if (content is String) return content;
    }
    return '';
  }

  String _errorFromBody(int status, String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'];
      final message = error is Map ? error['message'] : null;
      if (message is String) return 'OpenAI API ($status): $message';
    } catch (_) {}
    return 'OpenAI API ($status): $body';
  }
}
