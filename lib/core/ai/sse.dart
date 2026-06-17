import 'dart:convert';

import 'package:http/http.dart' as http;

/// Zamienia strumieniową odpowiedź HTTP (Server-Sent Events)
/// na strumień zawartości linii `data: ...`.
Stream<String> sseDataLines(http.StreamedResponse response) async* {
  final lines = response.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in lines) {
    if (line.startsWith('data:')) {
      yield line.substring(5).trim();
    }
  }
}
