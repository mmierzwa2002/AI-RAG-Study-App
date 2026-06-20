import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_settings.dart';
import 'settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AiProvider _provider;
  late final TextEditingController _anthropicKey;
  late final TextEditingController _anthropicModel;
  late final TextEditingController _openaiKey;
  late final TextEditingController _openaiModel;
  late final TextEditingController _openaiBaseUrl;
  late final TextEditingController _geminiKey;
  late final TextEditingController _geminiModel;
  late final TextEditingController _geminiEmbeddingModel;
  late final TextEditingController _openaiEmbeddingModel;
  bool _showKeys = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsCubit>().state;
    _provider = s.provider;
    _anthropicKey = TextEditingController(text: s.anthropicApiKey);
    _anthropicModel = TextEditingController(text: s.anthropicModel);
    _openaiKey = TextEditingController(text: s.openaiApiKey);
    _openaiModel = TextEditingController(text: s.openaiModel);
    _openaiBaseUrl = TextEditingController(text: s.openaiBaseUrl);
    _geminiKey = TextEditingController(text: s.geminiApiKey);
    _geminiModel = TextEditingController(text: s.geminiModel);
    _geminiEmbeddingModel =
        TextEditingController(text: s.geminiEmbeddingModel);
    _openaiEmbeddingModel =
        TextEditingController(text: s.openaiEmbeddingModel);
  }

  @override
  void dispose() {
    _anthropicKey.dispose();
    _anthropicModel.dispose();
    _openaiKey.dispose();
    _openaiModel.dispose();
    _openaiBaseUrl.dispose();
    _geminiKey.dispose();
    _geminiModel.dispose();
    _geminiEmbeddingModel.dispose();
    _openaiEmbeddingModel.dispose();
    super.dispose();
  }

  void _save() {
    const defaults = AppSettings();
    final settings = AppSettings(
      provider: _provider,
      anthropicApiKey: _anthropicKey.text.trim(),
      openaiApiKey: _openaiKey.text.trim(),
      geminiApiKey: _geminiKey.text.trim(),
      anthropicModel: _anthropicModel.text.trim().isEmpty
          ? defaults.anthropicModel
          : _anthropicModel.text.trim(),
      openaiModel: _openaiModel.text.trim().isEmpty
          ? defaults.openaiModel
          : _openaiModel.text.trim(),
      geminiModel: _geminiModel.text.trim().isEmpty
          ? defaults.geminiModel
          : _geminiModel.text.trim(),
      openaiBaseUrl: _openaiBaseUrl.text.trim().isEmpty
          ? defaults.openaiBaseUrl
          : _openaiBaseUrl.text.trim(),
      geminiEmbeddingModel: _geminiEmbeddingModel.text.trim().isEmpty
          ? defaults.geminiEmbeddingModel
          : _geminiEmbeddingModel.text.trim(),
      openaiEmbeddingModel: _openaiEmbeddingModel.text.trim().isEmpty
          ? defaults.openaiEmbeddingModel
          : _openaiEmbeddingModel.text.trim(),
    );
    context.read<SettingsCubit>().save(settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zapisano ustawienia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dostawca AI', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<AiProvider>(
            segments: const [
              ButtonSegment(
                value: AiProvider.gemini,
                label: Text('Gemini'),
                icon: Icon(Icons.auto_awesome),
              ),
              ButtonSegment(
                value: AiProvider.anthropic,
                label: Text('Claude'),
                icon: Icon(Icons.psychology),
              ),
              ButtonSegment(
                value: AiProvider.openai,
                label: Text('Inne'),
                icon: Icon(Icons.api),
              ),
            ],
            selected: {_provider},
            onSelectionChanged: (selection) =>
                setState(() => _provider = selection.first),
          ),
          const SizedBox(height: 24),
          if (_provider == AiProvider.gemini) ...[
            Text('Google Gemini (Zalecane - Darmowe)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _geminiKey,
              obscureText: !_showKeys,
              decoration: InputDecoration(
                labelText: 'Klucz API Gemini',
                helperText: 'Pobierz na aistudio.google.com',
                border: const OutlineInputBorder(),
                suffixIcon: _visibilityToggle(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _geminiModel,
              decoration: const InputDecoration(
                labelText: 'Model Gemini',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _geminiEmbeddingModel,
              decoration: const InputDecoration(
                labelText: 'Model embeddingów (baza wektorowa)',
                helperText: 'Domyślnie text-embedding-004',
                border: OutlineInputBorder(),
              ),
            ),
          ] else if (_provider == AiProvider.anthropic) ...[
            Text('Anthropic Claude (Płatne)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _anthropicKey,
              obscureText: !_showKeys,
              decoration: InputDecoration(
                labelText: 'Klucz API Anthropic',
                helperText: 'console.anthropic.com',
                border: const OutlineInputBorder(),
                suffixIcon: _visibilityToggle(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anthropicModel,
              decoration: const InputDecoration(
                labelText: 'Model Anthropic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anthropic nie udostępnia API embeddingów, więc dla tego '
              'dostawcy wyszukiwanie w materiałach działa po słowach '
              'kluczowych (TF-IDF), bez bazy wektorowej.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (_provider == AiProvider.openai) ...[
            Text('OpenAI lub inne (Groq, OpenRouter, Ollama)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _openaiBaseUrl,
              decoration: const InputDecoration(
                labelText: 'Adres bazowy API (base URL)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _openaiKey,
              obscureText: !_showKeys,
              decoration: InputDecoration(
                labelText: 'Klucz API',
                border: const OutlineInputBorder(),
                suffixIcon: _visibilityToggle(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _openaiModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _openaiEmbeddingModel,
              decoration: const InputDecoration(
                labelText: 'Model embeddingów (baza wektorowa)',
                helperText: 'Dla Ollamy: nomic-embed-text',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Zapisz ustawienia'),
          ),
          const SizedBox(height: 24),
          Card(
            color: scheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.info_outline,
                    text: 'Dla darmowego działania wybierz Gemini i wklej klucz z Google AI Studio.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visibilityToggle() => IconButton(
        icon: Icon(_showKeys ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _showKeys = !_showKeys),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
