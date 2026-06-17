/// Bazowy wyjątek aplikacji — [toString] zwraca komunikat gotowy
/// do pokazania użytkownikowi (np. w SnackBarze).
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Błąd zwrócony przez dostawcę AI (Anthropic / OpenAI).
class AiException extends AppException {
  const AiException(super.message);
}
