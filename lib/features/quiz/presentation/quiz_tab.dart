import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/quiz_question.dart';
import 'quiz_cubit.dart';

const _correctFill = Color(0x1F4CAF50);
const _correctBorder = Color(0xFF4CAF50);
const _wrongFill = Color(0x1FF44336);
const _wrongBorder = Color(0xFFF44336);

class QuizTab extends StatelessWidget {
  const QuizTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizCubit, QuizState>(
      listenWhen: (prev, curr) =>
          curr.error != null && prev.error != curr.error,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        switch (state.status) {
          case QuizStatus.idle:
            return _IdleView(onGenerate: context.read<QuizCubit>().generate);
          case QuizStatus.generating:
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Układam pytania z Twoich materiałów…'),
                ],
              ),
            );
          case QuizStatus.inProgress:
            return _QuestionView(state: state);
          case QuizStatus.finished:
            return _ResultView(state: state);
        }
      },
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onGenerate});

  final Future<void> Function(int count) onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              'Sprawdź swoją wiedzę',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'AI ułoży quiz jednokrotnego wyboru\nz materiałów tego przedmiotu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => onGenerate(5),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Quiz — 5 pytań'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => onGenerate(10),
              child: const Text('Dłuższy quiz — 10 pytań'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final question = state.questions[state.current];
    final isLast = state.current == state.questions.length - 1;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(
          value: (state.current + (state.revealed ? 1 : 0)) /
              state.questions.length,
        ),
        const SizedBox(height: 12),
        Text(
          'Pytanie ${state.current + 1} z ${state.questions.length}'
          ' • wynik: ${state.correctCount}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Text(question.question,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++)
          _OptionTile(index: i, question: question, state: state),
        if (state.revealed && question.explanation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(question.explanation)),
                ],
              ),
            ),
          ),
        ],
        if (state.revealed) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: context.read<QuizCubit>().next,
            child: Text(isLast ? 'Zobacz wynik' : 'Następne pytanie'),
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.question,
    required this.state,
  });

  final int index;
  final QuizQuestion question;
  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? fill;
    Color border = scheme.outlineVariant;
    Widget? trailing;
    if (state.revealed) {
      if (index == question.correctIndex) {
        fill = _correctFill;
        border = _correctBorder;
        trailing = const Icon(Icons.check_circle, color: _correctBorder);
      } else if (index == state.selected) {
        fill = _wrongFill;
        border = _wrongBorder;
        trailing = const Icon(Icons.cancel, color: _wrongBorder);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: state.revealed
            ? null
            : () => context.read<QuizCubit>().answer(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D…
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(question.options[index])),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final total = state.questions.length;
    final percent = total == 0 ? 0 : (state.correctCount * 100 / total).round();
    final message = percent >= 80
        ? 'Świetnie! Materiał masz w małym palcu.'
        : percent >= 50
            ? 'Nieźle, ale warto powtórzyć słabsze tematy.'
            : 'Warto wrócić do materiałów — spróbuj trybu odpytywania w czacie.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.correctCount} / $total',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text('$percent% poprawnych odpowiedzi'),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: context.read<QuizCubit>().restart,
              icon: const Icon(Icons.replay),
              label: const Text('Rozwiąż jeszcze raz'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: context.read<QuizCubit>().reset,
              child: const Text('Nowy quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
