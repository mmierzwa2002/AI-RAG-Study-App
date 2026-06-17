import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/date_x.dart';
import '../domain/study_material.dart';
import 'materials_cubit.dart';

class MaterialsTab extends StatelessWidget {
  const MaterialsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MaterialsCubit, MaterialsState>(
      listenWhen: (prev, curr) =>
          curr.error != null && prev.error != curr.error,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed:
                          state.processing ? null : () => _pickPdf(context),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Dodaj PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed:
                          state.processing ? null : () => _pickImage(context),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Dodaj zdjęcie'),
                    ),
                  ),
                ],
              ),
            ),
            if (state.processing)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Przetwarzam materiał… (zdjęcia notatek przepisuje '
                      'model AI, to może chwilę potrwać)',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.materials.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: state.materials.length,
                          itemBuilder: (context, index) =>
                              _MaterialTile(material: state.materials[index]),
                        ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickPdf(BuildContext context) async {
    final cubit = context.read<MaterialsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nie udało się odczytać pliku.')),
      );
      return;
    }
    await cubit.addPdf(fileName: file.name, bytes: bytes);
  }

  Future<void> _pickImage(BuildContext context) async {
    final cubit = context.read<MaterialsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Zrób zdjęcie notatek'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Wybierz z galerii'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await cubit.addImage(
        fileName: picked.name,
        bytes: bytes,
        mimeType: _mimeFromName(picked.name),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Nie udało się pobrać zdjęcia: $e')),
      );
    }
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material});

  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          material.kind == MaterialKind.pdf
              ? Icons.picture_as_pdf_outlined
              : Icons.image_outlined,
        ),
        title: Text(material.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${material.charCount} znaków • ${material.chunkCount} fragmentów'
          ' • ${material.createdAt.ddMMyyyy}',
        ),
        trailing: IconButton(
          tooltip: 'Usuń materiał',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<MaterialsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Usunąć „${material.name}”?'),
        content: const Text(
          'Fragmenty tego materiału znikną z bazy wiedzy przedmiotu.',
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
      await cubit.remove(material.id);
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
            Icon(Icons.note_add_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              'Brak materiałów',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dodaj PDF z wykładu albo zdjęcie notatek —\n'
              'AI będzie odpowiadać na ich podstawie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
