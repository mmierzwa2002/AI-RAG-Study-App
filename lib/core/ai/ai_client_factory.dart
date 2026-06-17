import 'package:http/http.dart' as http;

import '../../features/settings/domain/app_settings.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../error/app_exception.dart';
import 'ai_client.dart';
import 'anthropic_client.dart';
import 'openai_client.dart';

/// Tworzy klienta AI zgodnie z aktualnymi ustawieniami użytkownika
/// (dostawca, klucz API, nazwa modelu).
class AiClientFactory {
  AiClientFactory(this._settings, this._http);

  final SettingsRepository _settings;
  final http.Client _http;

  Future<AiClient> create() async {
    final s = await _settings.load();
    switch (s.provider) {
      case AiProvider.anthropic:
        if (s.anthropicApiKey.trim().isEmpty) {
          throw const AppException(
            'Brak klucza API Anthropic. Dodaj go w Ustawieniach.',
          );
        }
        return AnthropicClient(
          apiKey: s.anthropicApiKey.trim(),
          model: s.anthropicModel,
          httpClient: _http,
        );
      case AiProvider.openai:
        final baseUrl = s.openaiBaseUrl.trim().isEmpty
            ? const AppSettings().openaiBaseUrl
            : s.openaiBaseUrl.trim();
        
        // Sprawdzamy czy to lokalna Ollama lub inne lokalne API (nie wymaga klucza)
        final isLocal =
            baseUrl.contains('localhost') || 
            baseUrl.contains('127.0.0.1') || 
            baseUrl.contains('10.0.2.2');

        if (s.openaiApiKey.trim().isEmpty && !isLocal) {
          throw const AppException(
            'Brak klucza API OpenAI. Dodaj go w Ustawieniach.',
          );
        }
        return OpenAiClient(
          apiKey: s.openaiApiKey.trim(),
          model: s.openaiModel,
          baseUrl: baseUrl,
          httpClient: _http,
        );
      case AiProvider.gemini:
        if (s.geminiApiKey.trim().isEmpty) {
          throw const AppException(
            'Brak klucza API Gemini. Pobierz go za darmo na aistudio.google.com i wklej w Ustawieniach.',
          );
        }
        return OpenAiClient(
          apiKey: s.geminiApiKey.trim(),
          model: s.geminiModel,
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
          httpClient: _http,
        );
    }
  }
}
