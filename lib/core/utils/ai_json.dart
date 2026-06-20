import 'dart:convert';

import '../error/app_exception.dart';

/// Wyciąga listę JSON z odpowiedzi modelu.
///
/// Modele (zwłaszcza małe, lokalne) bywają niechlujne: owijają JSON w blok
/// ```json ... ```, doklejają komentarz przed/po, albo w trybie JSON zwracają
/// tablicę opakowaną w obiekt, np. {"fiszki": [...]}. Ta funkcja radzi sobie
/// ze wszystkimi tymi przypadkami.
List<dynamic> extractJsonList(String raw) {
  var text = raw.trim();

  // 1. Usuwamy bloki kodu markdown (```json ... ``` lub ``` ... ```).
  final fence = RegExp(r'```(?:json)?([\s\S]*?)```').firstMatch(text);
  if (fence != null) {
    text = fence.group(1)!.trim();
  }

  // 2. Najpierw próbujemy sparsować całość: model może zwrócić samą tablicę
  //    albo obiekt z jedną wartością-tablicą (tryb JSON często tak robi).
  final fromWhole = _asList(_tryDecode(text));
  if (fromWhole != null) return fromWhole;

  // 3. Wycinamy fragment od pierwszej [ do ostatniej ] i próbujemy naprawić
  //    typowy błąd: przecinek na końcu listy.
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start != -1 && end > start) {
    final candidate = text.substring(start, end + 1);
    final parsed = _tryDecode(candidate) ??
        _tryDecode(candidate.replaceAll(RegExp(r',\s*\]'), ']'));
    final asList = _asList(parsed);
    if (asList != null) return asList;
  }

  // 4. Ostatnia szansa: obiekt {...} - albo z tablicą w środku, albo
  //    pojedynczy obiekt traktowany jako jednoelementowa lista.
  final objStart = text.indexOf('{');
  final objEnd = text.lastIndexOf('}');
  if (objStart != -1 && objEnd > objStart) {
    final obj = _tryDecode(text.substring(objStart, objEnd + 1));
    final asList = _asList(obj);
    if (asList != null) return asList;
    if (obj is Map) return [obj];
  }

  throw const AppException(
    'Model nie zwrócił poprawnego JSON-a. Spróbuj ponownie.',
  );
}

dynamic _tryDecode(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

/// Zwraca listę, gdy [value] jest listą albo obiektem z dokładnie jedną
/// wartością będącą listą (np. {"fiszki": [...]} -> [...]).
List<dynamic>? _asList(dynamic value) {
  if (value is List) return value;
  if (value is Map) {
    final lists = value.values.whereType<List>().toList();
    if (lists.length == 1) return lists.first;
  }
  return null;
}
