import 'package:equatable/equatable.dart';

enum AiProvider { anthropic, openai, gemini }

class AppSettings extends Equatable {
  const AppSettings({
    this.provider = AiProvider.gemini,
    this.anthropicApiKey = '',
    this.openaiApiKey = '',
    this.geminiApiKey = '',
    this.anthropicModel = 'claude-3-5-sonnet-20240620',
    this.openaiModel = 'gpt-4o-mini',
    this.geminiModel = 'gemini-2.5-flash',
    this.openaiBaseUrl = 'https://api.openai.com/v1',
    this.geminiEmbeddingModel = 'text-embedding-004',
    this.openaiEmbeddingModel = 'text-embedding-3-small',
  });

  final AiProvider provider;
  final String anthropicApiKey;
  final String openaiApiKey;
  final String geminiApiKey;
  final String anthropicModel;
  final String openaiModel;
  final String geminiModel;

  /// Adres bazowy API kompatybilnego z OpenAI.
  final String openaiBaseUrl;

  /// Model embeddingów (baza wektorowa) dla Gemini.
  final String geminiEmbeddingModel;

  /// Model embeddingów dla OpenAI i kompatybilnych.
  /// Dla lokalnej Ollamy wpisz "nomic-embed-text".
  final String openaiEmbeddingModel;

  bool get hasKeyForProvider => switch (provider) {
        AiProvider.anthropic => anthropicApiKey.trim().isNotEmpty,
        AiProvider.openai => openaiApiKey.trim().isNotEmpty,
        AiProvider.gemini => geminiApiKey.trim().isNotEmpty,
      };

  AppSettings copyWith({
    AiProvider? provider,
    String? anthropicApiKey,
    String? openaiApiKey,
    String? geminiApiKey,
    String? anthropicModel,
    String? openaiModel,
    String? geminiModel,
    String? openaiBaseUrl,
    String? geminiEmbeddingModel,
    String? openaiEmbeddingModel,
  }) =>
      AppSettings(
        provider: provider ?? this.provider,
        anthropicApiKey: anthropicApiKey ?? this.anthropicApiKey,
        openaiApiKey: openaiApiKey ?? this.openaiApiKey,
        geminiApiKey: geminiApiKey ?? this.geminiApiKey,
        anthropicModel: anthropicModel ?? this.anthropicModel,
        openaiModel: openaiModel ?? this.openaiModel,
        geminiModel: geminiModel ?? this.geminiModel,
        openaiBaseUrl: openaiBaseUrl ?? this.openaiBaseUrl,
        geminiEmbeddingModel: geminiEmbeddingModel ?? this.geminiEmbeddingModel,
        openaiEmbeddingModel: openaiEmbeddingModel ?? this.openaiEmbeddingModel,
      );

  @override
  List<Object?> get props => [
        provider,
        anthropicApiKey,
        openaiApiKey,
        geminiApiKey,
        anthropicModel,
        openaiModel,
        geminiModel,
        openaiBaseUrl,
        geminiEmbeddingModel,
        openaiEmbeddingModel,
      ];
}
