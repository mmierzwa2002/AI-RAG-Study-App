import 'package:flutter/material.dart';

import '../domain/flashcard.dart';

/// Tryb nauki: przesuwaj karty w bok, dotknij kartę, aby ją odwrócić.
class FlashcardStudyPage extends StatefulWidget {
  const FlashcardStudyPage({
    super.key,
    required this.cards,
    required this.subjectName,
  });

  final List<Flashcard> cards;
  final String subjectName;

  @override
  State<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends State<FlashcardStudyPage> {
  final _flipped = <int>{};
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Fiszki — ${widget.subjectName}')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: widget.cards.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final card = widget.cards[i];
                final showBack = _flipped.contains(i);
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (showBack) {
                        _flipped.remove(i);
                      } else {
                        _flipped.add(i);
                      }
                    }),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _CardFace(
                        key: ValueKey('$i-$showBack'),
                        label: showBack ? 'ODPOWIEDŹ' : 'PYTANIE',
                        text: showBack ? card.back : card.front,
                        highlighted: showBack,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${_index + 1} / ${widget.cards.length} • dotknij kartę, '
                'aby ją odwrócić',
                style: TextStyle(color: scheme.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    required this.label,
    required this.text,
    required this.highlighted,
  });

  final String label;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color:
          highlighted ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: highlighted
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
