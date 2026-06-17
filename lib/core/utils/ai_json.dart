import 'dart:convert';

import '../error/app_exception.dart';

/// Wyciąga listę JSON z odpowiedzi modelu — modele potrafią owinąć JSON
/// w blok ```json ... ``` albo dopisać komentarz przed/po liście.
List<dynamic> extractJsonList(String raw) {
  var text = raw.trim();
  
  // 1. Usuwamy bloki kodu markdown (```json ... ``` lub ``` ... ```)
  final fence = RegExp(r'```(?:json)?([\s\S]*?)```').firstMatch(text);
  if (fence != null) {
    text = fence.group(1)!.trim();
  }
  
  // 2. Szukamy pierwszej [ i ostatniej ] - to nasza tablica
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  
  if (start == -1 || end == -1 || end <= start) {
    // Jeśli nie ma tablicy, może model zwrócił pojedynczy obiekt w {}?
    final objStart = text.indexOf('{');
    final objEnd = text.lastIndexOf('}');
    if (objStart != -1 && objEnd > objStart) {
       try {
         final obj = jsonDecode(text.substring(objStart, objEnd + 1));
         return [obj]; // Zwracamy jako listę jednoelementową
       } catch (_) {}
    }
    
    throw const AppException(
      'Model nie zwrócił poprawnego JSON-a. Spróbuj ponownie.',
    );
  }

  final jsonCandidate = text.substring(start, end + 1);
  
  try {
    return jsonDecode(jsonCandidate) as List<dynamic>;
  } on FormatException {
    // 3. Próba "naprawy" typowych błędów modeli (np. przecinek na końcu listy)
    try {
      final fixed = jsonCandidate.replaceAll(RegExp(r',\s*\]'), ']');
      return jsonDecode(fixed) as List<dynamic>;
    } catch (_) {
      throw const AppException(
        'Nie udało się przetworzyć odpowiedzi modelu. Spróbuj ponownie.',
      );
    }
  }
}
