import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_x.dart';
import '../../settings/presentation/settings_page.dart';
import '../domain/subject.dart';
import 'subject_page.dart';
import 'subjects_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asystent nauki AI'),
        actions: [
          IconButton(
            tooltip: 'Ustawienia',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Przedmiot'),
      ),
      body: BlocConsumer<SubjectsCubit, SubjectsState>(
        listenWhen: (prev, curr) =>
            curr.error != null && prev.error != curr.error,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.subjects.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: state.subjects.length,
            itemBuilder: (context, index) =>
                _SubjectTile(subject: state.subjects[index]),
          );
        },
      ),
    );
  }

  Future<void> _showAddSubjectDialog(BuildContext context) async {
    final cubit = context.read<SubjectsCubit>();
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nowy przedmiot'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'np. Analiza matematyczna',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(controller.text);
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    // Czekamy chwilę na animację zamknięcia dialogu zanim zrobimy dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (name != null && name.trim().isNotEmpty) {
      await cubit.add(name);
    }
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme
        .subjectPalette[subject.colorIndex % AppTheme.subjectPalette.length];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Text(
            subject.name.isEmpty ? '?' : subject.name[0].toUpperCase(),
          ),
        ),
        title: Text(subject.name),
        subtitle: Text('Utworzono ${subject.createdAt.ddMMyyyy}'),
        trailing: IconButton(
          tooltip: 'Usuń przedmiot',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SubjectPage(subject: subject)),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<SubjectsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Usunąć „${subject.name}”?'),
        content: const Text(
          'Skasuje to też wszystkie materiały, historię czatu i fiszki '
          'tego przedmiotu.',
        ),
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
      await cubit.remove(subject.id);
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
            Icon(Icons.school_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'Dodaj pierwszy przedmiot',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Potem wrzucisz do niego PDF-y i zdjęcia notatek,\n'
              'a AI pomoże Ci się z nich uczyć.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
