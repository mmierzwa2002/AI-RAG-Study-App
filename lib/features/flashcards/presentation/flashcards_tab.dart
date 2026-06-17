import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'flashcard_study_page.dart';
import 'flashcards_cubit.dart';

class FlashcardsTab extends StatelessWidget {
  const FlashcardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlashcardsCubit, FlashcardsState>(
      listenWhen: (prev, curr) =>
          curr.error != null && prev.error != curr.error,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final cubit = context.read<FlashcardsCubit>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: state.generating
                          ? null
                          : () => cubit.generate(count: 10),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Generuj 10 fiszek'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: state.cards.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FlashcardStudyPage(
                                    cards: state.cards,
                                    subjectName: cubit.subject.name,
                                  ),
                                ),
                              ),
                      icon: const Icon(Icons.style_outlined),
                      label: const Text('Ucz się'),
                    ),
                  ),
                ],
              ),
            ),
            if (state.generating)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Generuję fiszki z Twoich materiałów…'),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    'Fiszki: ${state.cards.length}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (state.cards.isNotEmpty)
                    IconButton(
                      tooltip: 'Usuń wszystkie fiszki',
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: () => _confirmClear(context),
                    ),
                ],
              ),
            ),
            Expanded(
              child: state.cards.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: state.cards.length,
                      itemBuilder: (context, index) {
                        final card = state.cards[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ExpansionTile(
                            title: Text(card.front),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(16, 0, 8, 8),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.back,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => context
                                      .read<FlashcardsCubit>()
                                      .removeCard(card.id),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Usuń'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final cubit = context.read<FlashcardsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usunąć wszystkie fiszki?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.clearAll();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              'Brak fiszek',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dodaj materiały, a potem wygeneruj z nich fiszki\n'
              'jednym przyciskiem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
