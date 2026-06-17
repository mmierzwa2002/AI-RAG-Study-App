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
    this.geminiModel = 'gemini-1.5-flash',
    this.openaiBaseUrl = 'https://api.openai.com/v1',
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
      ];
}
