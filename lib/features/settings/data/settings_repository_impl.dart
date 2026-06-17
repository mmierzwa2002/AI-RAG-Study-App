import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

/// Ustawienia trzymamy w SharedPreferences.
///
/// Uwaga: klucz API zostaje wyłącznie na urządzeniu, ale w aplikacji
/// produkcyjnej powinien żyć na backendzie (proxy), a nie w kliencie.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _kProvider = 'settings_provider';
  static const _kAnthropicKey = 'settings_anthropic_key';
  static const _kOpenaiKey = 'settings_openai_key';
  static const _kGeminiKey = 'settings_gemini_key';
  static const _kAnthropicModel = 'settings_anthropic_model';
  static const _kOpenaiModel = 'settings_openai_model';
  static const _kGeminiModel = 'settings_gemini_model';
  static const _kOpenaiBaseUrl = 'settings_openai_base_url';

  @override
  Future<AppSettings> load() async {
    const defaults = AppSettings();
    final providerName = _prefs.getString(_kProvider);
    final provider = AiProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => defaults.provider,
    );
    return AppSettings(
      provider: provider,
      anthropicApiKey:
          _prefs.getString(_kAnthropicKey) ?? defaults.anthropicApiKey,
      openaiApiKey: _prefs.getString(_kOpenaiKey) ?? defaults.openaiApiKey,
      geminiApiKey: _prefs.getString(_kGeminiKey) ?? defaults.geminiApiKey,
      anthropicModel:
          _prefs.getString(_kAnthropicModel) ?? defaults.anthropicModel,
      openaiModel: _prefs.getString(_kOpenaiModel) ?? defaults.openaiModel,
      geminiModel: _prefs.getString(_kGeminiModel) ?? defaults.geminiModel,
      openaiBaseUrl:
          _prefs.getString(_kOpenaiBaseUrl) ?? defaults.openaiBaseUrl,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_kProvider, settings.provider.name);
    await _prefs.setString(_kAnthropicKey, settings.anthropicApiKey);
    await _prefs.setString(_kOpenaiKey, settings.openaiApiKey);
    await _prefs.setString(_kGeminiKey, settings.geminiApiKey);
    await _prefs.setString(_kAnthropicModel, settings.anthropicModel);
    await _prefs.setString(_kOpenaiModel, settings.openaiModel);
    await _prefs.setString(_kGeminiModel, settings.geminiModel);
    await _prefs.setString(_kOpenaiBaseUrl, settings.openaiBaseUrl);
  }
}
