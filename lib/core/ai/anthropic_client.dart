import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../error/app_exception.dart';
import 'ai_client.dart';
import 'sse.dart';

/// Klient Anthropic Messages API (https://docs.claude.com/en/api).
class AnthropicClient implements AiClient {
  AnthropicClient({
    required this.apiKey,
    required this.model,
    required http.Client httpClient,
  }) : _http = httpClient;

  final String apiKey;
  final String model;
  final http.Client _http;

  static final Uri _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
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
        'max_tokens': maxTokens,
        'system': system,
        'stream': true,
        'messages': [
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
      if (data.isEmpty || data == '[DONE]') continue;
      Map<String, dynamic> event;
      try {
        event = jsonDecode(data) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      final type = event['type'];
      if (type == 'content_block_delta') {
        final delta = event['delta'];
        final text = delta is Map ? delta['text'] : null;
        if (text is String) yield text;
      } else if (type == 'error') {
        final err = event['error'];
        final message = err is Map ? err['message'] : null;
        throw AiException('Błąd API Anthropic: ${message ?? data}');
      } else if (type == 'message_stop') {
        return;
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
      'max_tokens': maxTokens,
      'system': system,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });
    return _textFromContent(json['content']);
  }

  @override
  Future<String> transcribeImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final json = await _post({
      'model': model,
      'max_tokens': 4096,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mimeType,
                'data': base64Encode(bytes),
              },
            },
            {
              'type': 'text',
              'text': 'Przepisz dokładnie cały tekst widoczny na tym zdjęciu '
                  'notatek. Zachowaj strukturę (nagłówki, listy), a wzory '
                  'i symbole zapisz tekstowo. Zwróć wyłącznie przepisany '
                  'tekst, bez żadnych komentarzy.',
            },
          ],
        },
      ],
    });
    return _textFromContent(json['content']);
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

  String _textFromContent(dynamic content) {
    if (content is List) {
      return content
          .whereType<Map>()
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String? ?? '')
          .join();
    }
    return '';
  }

  String _errorFromBody(int status, String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'];
      final message = error is Map ? error['message'] : null;
      if (message is String) return 'Anthropic API ($status): $message';
    } catch (_) {}
    return 'Anthropic API ($status): $body';
  }
}
